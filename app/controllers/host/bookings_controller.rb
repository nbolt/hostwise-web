class Host::BookingsController < Host::AuthController
  expose(:property) { Property.find_by_slug params[:slug] }
  expose(:booking)  { Booking.find_by_id params[:booking] }

  def show
    render json: booking.to_json(include: [:services, :payment])
  end

  def update
    if params[:services]
      booking.payment = Payment.find params[:payment]
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
    else
      render json: { success: false, message: 'Please select at least one service' }
    end
  end

  def cancel
    UserMailer.cancelled_booking_notification(booking).then(:deliver)
    if params[:apply_fee]
      if booking.update_attribute :status, :cancelled
        booking.charge!
        render json: { success: true }
      else
        render json: { success: false }
      end
    else
      if booking.update_attribute :status, :deleted
        render json: { success: true }
      else
        render json: { success: false }
      end
    end
  end

  def same_day_cancellation
    render json: { same_day_cancellation: booking.same_day_cancellation }
  end
end
