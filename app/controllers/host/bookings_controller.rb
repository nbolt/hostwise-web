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
        booking.services.destroy service unless params[:services].find {|s| service.name == s}
      end
      params[:services].each do |service|
        booking.services.push Service.where(name: service)[0] unless booking.services.find {|s| service == s.name}
      end
      if booking.save
        booking.update_cost!
        render json: { success: true }
      else
        render json: { success: false }
      end
    else
      render json: { success: false, message: 'Please select at least one service' }
    end
  end

  def cancel
    unless booking.status == :cancelled || booking.status == :deleted
      UserMailer.cancelled_booking_notification(booking).then(:deliver)
      if booking.job
        booking.job.update_attribute :status_cd, 6
        booking.job.contractors.each do |contractor|
          contractor.payouts.create(job_id: booking.job.id, amount: booking.job.payout(contractor) * 100) if params[:apply_fee]
          booking.job.contractors.destroy contractor
          if contractor.contractor_profile.position == :trainee
            TwilioJob.perform_later("+1#{contractor.phone_number}", "Oops! Your Test & Tips session on #{booking.job.formatted_date} was cancelled. Please select another session!")
          else
            TwilioJob.perform_later("+1#{contractor.phone_number}", "Oops! Looks like job ##{booking.job.id} on #{booking.job.formatted_date} was cancelled. Sorry about this!")
          end
        end
      end
      if params[:apply_fee]
        if booking.update_attribute :status, :cancelled
          booking.update_cost!
          booking.charge!
          UserMailer.booking_same_day_cancellation(booking).then(:deliver)
          render json: { success: true }
        else
          render json: { success: false }
        end
      else
        if booking.update_attribute :status, :deleted
          UserMailer.booking_cancellation(booking).then(:deliver)
          render json: { success: true }
        else
          render json: { success: false }
        end
      end
    end
  end

  def same_day_cancellation
    render json: { same_day_cancellation: booking.same_day_cancellation }
  end
end
