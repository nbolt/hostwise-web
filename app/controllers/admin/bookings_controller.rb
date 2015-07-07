require 'csv'

class Admin::BookingsController < Admin::AuthController
  expose(:booking) { Booking.find params[:id] }

  def index
    if params[:id]
      @bookings = [Booking.find_by_id(params[:id]),Property.find_by_id(params[:id])].compact
    else
      data = if params[:data] then JSON.parse params[:data] else nil end
      filtered_bookings = nil
      @bookings = Booking.where(status_cd: [2,3,4,5])
      @properties = Transaction.where('properties.id is not null and status_cd = 0').includes(:properties).references(:properties)
      @transactions = @bookings.concat @properties
      total = @transactions.count

      if data
        #@bookings = @bookings.search(data['search']['value']).to_a if data['search']['value'].present?
        data['columns'].each do |column|
          value = column['search']['value'].then(:downcase)
          if value.present?
            @transactions =
              case column['data']
              when 1  then @transactions.select {|transaction| (transaction.id).to_s.match value}
              when 2  then @transactions.select {|transaction| (transaction.class == Booking && transaction.job.id || nil).to_s.match value}
              when 3  then @transactions.select {|transaction| (transaction.chain(:property, :id) || transaction.id).to_s.match value}
              when 4  then @transactions.select {|transaction| (transaction.chain(:user, :id) || transaction.property.user.id).to_s.match value}
              when 6  then @transactions.select {|transaction| (transaction.chain(:user, :name) || transaction.property.user.name).downcase.match value}
              when 7  then @transactions.select {|transaction| ((transaction.class == Transaction && transaction.status_cd != 0 || transaction.payment_status_cd == 0) && 'Open' || 'Received').match value}
              when 8  then @transactions
              when 9  then @transactions
              when 10 then @transactions
              when 5  then @transactions.select do |transaction|
                from = value.split('|')[0]
                to   = value.split('|')[1]
                if from.then(:present?) && to.then(:present?)
                  date = transaction.date || transaction.charged_at
                  date >= Date.strptime(from, '%m/%d/%Y') && date <= Date.strptime(to, '%m/%d/%Y')
                else
                  true
                end
              end
              end
          end
        end
        data['order'].each do |order|
          dir = if order['dir'] == 'asc' then 1 else -1 end
          @transactions =
            case order['column']
            when 0 then @transactions
            when 1 then @transactions.sort_by {|transaction| dir * transaction.id}
            when 2 then @transactions.sort_by {|transaction| dir * (transaction.class == Booking && transaction.job.id || 0)}
            when 3 then @transactions.sort_by {|transaction| dir * (transaction.chain(:property, :id) || transaction.id)}
            when 4 then @transactions.sort_by {|transaction| dir * (transaction.chain(:user, :id) || transaction.property.user.id)}
            when 5 then @transactions.sort_by {|transaction| dir * (transaction.date || transaction.charged_at).to_time.to_i}
            end
        end
        filtered_bookings = @transactions
        @transactions = Kaminari.paginate_array(@transactions).page(data['start'] / data['length'] + 1).per(data['length']) if data['length'] > 0
      end
    end

    respond_to do |format|
      format.html
      format.json do
        render json: { meta: { total: total, filtered: filtered_bookings.then(:count) }, transactions: @transactions.map {|transaction| if transaction.class == Transaction then transaction.to_json(include: {properties: {include: {user: {methods: [:name]}}}}) else transaction.to_json(methods: [:cost, :original_cost], include: {job: {}, user: {methods: :name}, payment: {methods: [:display]}, property: {methods: :nickname, include: {user: {methods: :name}}}}) end}}
      end
      format.csv do
        headers['Content-Disposition'] = "attachment; filename=\"transactions.csv\""
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
