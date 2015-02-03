class Admin::ContractorsController < Admin::AuthController
  def index
    respond_to do |format|
      format.html
      format.json { render json: User.contractors.to_json(include: [contractor_profile: {methods: [:position]}], methods: [:name, :avatar, :next_job_date]) }
    end
  end

  def signup
    user = User.new(user_params)
    temp_pwd = rand(1000..9999)
    user.password = temp_pwd
    user.password_confirmation = temp_pwd
    user.role = :contractor
    user.step = 'contractor_info'

    if user.save
      UserMailer.contractor_welcome_email(user, activate_url(user.activation_token)).then(:deliver)

      render json: { success: true }
    else
      render json: { success: false, message: user.errors.full_messages[0] }
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.json { render json: User.find_by_id(params[:id]).to_json(include: [:background_check, contractor_profile: {methods: [:position, :ssn, :driver_license, :current_position]}], methods: [:name, :avatar]) }
    end
  end

  def update
    user = User.find_by_id params[:id]

    if params[:status].present?
      user.contractor_profile.position = params[:status].downcase.to_sym
      user.contractor_profile.save
      render json: user.to_json(include: [:background_check, contractor_profile: {methods: [:position, :ssn, :driver_license, :current_position]}], methods: [:name, :avatar])
    else
      user.assign_attributes contractor_params
      user.step = 'contractor_info'

      if user.valid?
        user.save
        contractor_profile_params = params[:contractor][:contractor_profile]
        profile = user.contractor_profile
        profile.address1 = contractor_profile_params[:address1]
        profile.address2 = contractor_profile_params[:address2]
        profile.zip = contractor_profile_params[:zip]
        profile.emergency_contact_first_name = contractor_profile_params[:emergency_contact_first_name]
        profile.emergency_contact_last_name = contractor_profile_params[:emergency_contact_last_name]
        profile.emergency_contact_phone = contractor_profile_params[:emergency_contact_phone]

        if profile.valid?
          profile.save
          render json: { success: true }
        else
          render json: { success: false, message: profile.errors.full_messages[0] }
        end
      else
        render json: { success: false, message: user.errors.full_messages[0] }
      end
    end
  end

  def deactivate
    User.find_by_id(params[:id]).deactivate!
    render json: { success: true }
  end

  def reactivate
    User.find_by_id(params[:id]).reactivate!
    render json: { success: true }
  end

  private

  def user_params
    params.require(:form).permit(:email, :password, :password_confirmation,
                                 :first_name, :last_name, :company, :phone_number)
  end

  def contractor_params
    params.require(:contractor).permit(:email, :first_name, :last_name, :phone_number, :secondary_phone)
  end
end