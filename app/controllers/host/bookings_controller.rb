class Host::BookingsController < Host::AuthController
  expose(:property) { Property.find_by_slug params[:slug] }
  expose(:booking)  { Booking.find_by_id params[:booking] }

  def show
    render json: booking.to_json(include: [:services, :payment])
  end

  def update
    booking.payment = Payment.find params[:payment][:id]
    booking.services.each do |service|
      booking.services.delete service unless params[:services].find {|s| service.name == s}
    end
    params[:services].each do |service|
      booking.services.push Service.where(name: service)[0] unless booking.services.find {|s| service == s.name}
    end
    if booking.save
      render json: { success: true }
    else
      render json: { success: false }
    end
  end

  def cancel
    booking.destroy
    if booking.destroyed?
      render json: { success: true }
    else
      render json: { success: false }
    end
  end

end
