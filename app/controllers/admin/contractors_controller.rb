class Admin::ContractorsController < Admin::AuthController
  def index
    respond_to do |format|
      format.html
      format.json { render json: User.contractors.to_json(include: [contractor_profile: {methods: [:position]}], methods: [:name, :avatar]) }
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

  private

  def user_params
    params.require(:form).permit(:email, :password, :password_confirmation,
                                 :first_name, :last_name, :company, :phone_number)
  end
end
