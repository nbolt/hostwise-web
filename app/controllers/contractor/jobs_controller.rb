class Contractor::JobsController < Contractor::AuthController

  expose(:booking) { Booking.find params[:id] }

  def claim
    if current_user.claim_job booking
      render json: { success: true }
    else
      render json: { success: false }
    end
  end

  def drop
    if current_user.drop_job booking
      render json: { success: true }
    else
      render json: { success: false }
    end
  end

end
