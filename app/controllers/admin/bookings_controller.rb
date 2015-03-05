require 'csv'

class Admin::BookingsController < Admin::AuthController
  
  def index
    if params[:id]
      @bookings = [Booking.find(params[:id])]
    else
      @bookings = Booking.all
      case params[:filter]
      when 'active'
        @bookings = @bookings.where(status_cd: [1,4])
      end
      @bookings = @bookings.search(params[:search]) if params[:search] && !params[:search].empty?
      @bookings = @bookings.order(params[:sort]).reverse
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

end
