class Contractor::AvailabilityController < Contractor::AuthController
  def index
    respond_to do |format|
      format.html
      format.json { render json: current_user.to_json(include: [:contractor_profile, :payments, :availability], methods: [:avatar, :name, :role]) }
    end
  end

  def add
    availability = current_user.availability
    if availability.present?
      availability.assign_attributes availability_params
    else
      availability = Availability.new availability_params
      availability.user = current_user
    end

    if availability.save
      render json: { success: true }
    else
      render json: { success: false, message: availability.errors.full_messages[0] }
    end
  end

  private

  def availability_params
    params.require(:form).permit(:mon, :tues, :wed, :thurs, :fri, :sat, :sun)
  end
end
