require 'csv'

class Admin::BookingsController < Admin::AuthController
  expose(:booking) { Booking.find params[:id] }

  def index
    if params[:id]
      @bookings = [Booking.find(params[:id])]
    else
      @bookings = Booking.all
      case params[:filter]
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
        render json: @bookings.to_json(include: {property: {methods: :nickname, include: {user: {methods: :name}}}})
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
        render json: booking.to_json(methods: [:cost], include: {services: {}, property: {methods: [:primary_photo, :full_address], include: {user: {methods: [:name, :display_phone_number, :avatar]}}}})
      end
    end
  end

end
