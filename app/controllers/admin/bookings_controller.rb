require 'csv'

class Admin::BookingsController < Admin::AuthController
  expose(:booking) { Booking.find params[:id] }

  def index
    if params[:id]
      @bookings = [Booking.find(params[:id])]
    else
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
    end

    respond_to do |format|
      format.html
      format.json do
        render json: { today: Booking.where(status_cd: [1,4]).today.reduce(0){|a,b|a + b.cost}, bookings: @bookings.to_json(methods: [:cost, :original_cost], include: {job: {}, user: {methods: :name}, payment: {methods: [:display]}, property: {methods: :nickname, include: {user: {methods: :name}}}}) }
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
      booking.overage_reason = ''
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
      booking.discounted_reason = ''
    end

    if booking.discounted == false && booking.overage == false
      booking.adjusted = false
      booking.adjusted_cost = 0
    end

    booking.save
    render json: { success: true }
  end

end
