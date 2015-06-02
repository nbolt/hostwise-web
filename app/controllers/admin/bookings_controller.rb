require 'csv'

class Admin::BookingsController < Admin::AuthController
  expose(:booking) { Booking.find params[:id] }

  def index
    if params[:id]
      @bookings = [Booking.find(params[:id])]
    else
      data = if params[:data] then JSON.parse params[:data] else nil end
      filtered_bookings = nil
      @bookings = Booking.all
      case params[:filter]
      when 'complete'
        @bookings = @bookings.where(status_cd: [2,3,4,5])
      when 'active'
        @bookings = @bookings.where(status_cd: [1,4])
      when 'future'
        @bookings = @bookings.where(status_cd: [1,4]).future
      end
      @bookings = @bookings.search(params[:search]) if params[:search] && !params[:search].empty?
      @bookings = @bookings.order(params[:sort])
      @bookings = @bookings.reverse if params[:sort] && params[:sort] == 'id'

      total = @bookings.count

      if data
        @bookings = @bookings.search(data['search']['value']).to_a if data['search']['value'].present?
        data['columns'].each do |column|
          value = column['search']['value'].then(:downcase)
          if value.present?
            @bookings =
              case column['data']
              when 1 then @bookings.select {|booking| booking.id.to_s.match value}
              when 2 then @bookings.select {|booking| booking.job.id.to_s.match value}
              when 3 then @bookings.select {|booking| booking.property.id.to_s.match value}
              when 4 then @bookings.select {|booking| booking.user.id.to_s.match value}
              when 5 then @bookings.select {|booking| booking.date.to_s.match value}
              when 6 then @bookings.select {|booking| booking.user.name.match value}
              when 7 then @bookings.select {|booking| (booking.payment_status_cd == 0 && 'Open' || 'Received').match value}
              when 8 then @bookings
              when 9 then @bookings
              when 10 then @bookings
              end
          end
        end
        data['order'].each do |order|
          dir = if order['dir'] == 'asc' then 1 else -1 end
          @bookings =
            case order['column']
            when 0 then @bookings
            when 1 then @bookings.sort_by {|booking| dir * booking.job.id}
            when 2 then @bookings.sort_by {|booking| dir * booking.property.id}
            when 3 then @bookings.sort_by {|booking| dir * booking.user.id}
            when 4 then @bookings.sort_by {|booking| dir * booking.date.to_time.to_i}
            end
        end
        filtered_bookings = @bookings
        @bookings = Kaminari.paginate_array(@bookings).page(data['start'] / data['length'] + 1).per(data['length'])
      end
    end

    respond_to do |format|
      format.html
      format.json do
        render json: { today: Booking.where(status_cd: [1,4]).today.reduce(0){|a,b|a + b.cost}, meta: { total: total, filtered: filtered_bookings.then(:count) }, bookings: @bookings.to_json(methods: [:cost, :original_cost], include: {job: {}, user: {methods: :name}, payment: {methods: [:display]}, property: {methods: :nickname, include: {user: {methods: :name}}}}) }
      end
      format.csv do
        headers['Content-Disposition'] = "attachment; filename=\"bookings.csv\""
        headers['Content-Type'] ||= 'text/csv'
      end
    end
  end

  def show
    respond_to do |format|
      format.html
      format.json do
        render json: booking.to_json(methods: [:cost], include: {job: {}, services: {}, property: {methods: [:primary_photo, :full_address, :nickname], include: {user: {methods: [:name, :display_phone_number, :avatar]}}}})
      end
    end
  end

  def refund
    refunded = (params[:refunded_cost].to_f * 100).to_i

    if refunded > booking.refunded_cost
      if booking.process_refund!(refunded, params[:refunded_reason])
        booking.refunded        = true
        booking.adjusted        = true
        booking.adjusted_cost   = booking.adjusted_cost - refunded
        booking.refunded_cost   = refunded
        booking.refunded_reason = params[:refunded_reason]
      else
        render json: { success: false, message: "Refund failed." }
        return
      end
    else
      render json: { success: false, message: "Can't refund for an amount less than what you've already refunded." }
      return
    end

    booking.save
    render json: { success: true, cost: booking.cost, adjusted: booking.adjusted, adjusted_cost: booking.adjusted_cost, refunded: booking.refunded, refunded_reason: booking.refunded_reason, refunded_cost: booking.refunded_cost }
  end

  def edit_payment
    adjusted   = params[:adjusted_cost].to_f   * 100
    overage    = params[:overage_cost].to_f    * 100
    discounted = params[:discounted_cost].to_f * 100

    if overage > 0
      booking.adjusted       = true
      booking.overage        = true
      booking.overage_cost   = overage
      booking.overage_reason = params[:overage_reason]
      booking.adjusted_cost  = adjusted
    else
      booking.overage        = false
      booking.overage_cost   = 0
      booking.overage_reason = nil
    end

    if discounted > 0
      booking.adjusted          = true
      booking.discounted        = true
      booking.discounted_cost   = discounted
      booking.discounted_reason = params[:discounted_reason]
      booking.adjusted_cost     = adjusted
    else
      booking.discounted        = false
      booking.discounted_cost   = 0
      booking.discounted_reason = nil
    end

    if !booking.discounted && !booking.overage
      booking.adjusted = false
      booking.adjusted_cost = 0
    end

    booking.save
    render json: { success: true }
  end

end
