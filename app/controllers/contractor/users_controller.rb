class Contractor::UsersController < Contractor::AuthController
  skip_before_filter :require_login, only: [:activate, :activated, :avatar]

  def update
    user = current_user
    if params[:step] == 'info'
      user.step = 'contractor_info'
      user.assign_attributes user_params
      if user.valid?
        user.save
        profile = user.contractor_profile
        edit_profile_params = params[:user][:contractor_profile]
        profile.address1 = edit_profile_params[:address1]
        profile.address2 = edit_profile_params[:address2]
        profile.zip = edit_profile_params[:zip]
        profile.emergency_contact_first_name = edit_profile_params[:emergency_contact_first_name]
        profile.emergency_contact_last_name = edit_profile_params[:emergency_contact_last_name]
        profile.emergency_contact_phone = edit_profile_params[:emergency_contact_phone]
        if profile.save
          render json: { success: true }
        else
          render json: { success: false, message: profile.errors.full_messages[0] }
        end
      else
        render json: { success: false, message: user.errors.full_messages[0] }
      end
    elsif params[:step] == 'password'
      user.step = 'edit_password'
      unless params[:user][:current_password].present?
        render json: { success: false, message: 'Current password is required' }
        return
      end
      unless User.authenticate(user.email, params[:user][:current_password]).present?
        render json: { success: false, message: "Current password doesn't match" }
        return
      end
      params[:user].delete :current_password #clear unpermitted param
      user.assign_attributes(user_params)
      if user.save
        render json: { success: true }
      else
        render json: { success: false, message: user.errors.full_messages[0] }
      end
    elsif params[:step] == 'photo'
      user.avatars.build(photo: params[:file]) # need to background this
      if user.save
        render json: { success: true }
      else
        render json: { success: false, message: user.errors.full_messages[0] }
      end
    end
  end

  def message
    message = current_user.messages.create({body: params[:form][:message]})
    if message.save
      #TODO: forward the message to support@useporter.com
      render json: { success: true }
    else
      render json: { success: false, message: message.errors.full_messages[0] }
    end
  end

  def activate
    user = User.load_from_activation_token(params[:id])
    if user
      respond_to do |format|
        format.html { render 'contractor/users/activate', layout: 'plain' }
        format.json { render json: user.to_json(include: [:contractor_profile], methods: [:avatar, :name, :role]) }
      end
    else
      not_authenticated
      return
    end
  end

  def activated
    user = User.load_from_activation_token(params[:id])
    user.assign_attributes user_params
    user.step = 'contractor_profile'
    user.phone_confirmed = true #hack for now

    if user.valid?
      profile = ContractorProfile.new
      profile.assign_attributes new_profile_params
      profile.position = :trainee

      if profile.valid?
        profile.save
        user.contractor_profile = profile
        user.availability = Availability.new({mon: true, tues: true, wed: true, thurs: true, fri: true, sat: true, sun: true})
        user.save
        user.activate!
        auto_login user
        render json: { success: true }
      else
        render json: { success: false, message: profile.errors.full_messages[0] }
      end
    else
      render json: { success: false, message: user.errors.full_messages[0] }
    end
  end

  def avatar
    user = User.load_from_activation_token(params[:id])
    user.avatars.build(photo: params[:file])

    if user.save
      render json: { success: true }
    else
      render json: { success: false, message: user.errors.full_messages[0] }
    end
  end

  def deactivate
    current_user.deactivate!
    logout
    render json: { success: true }
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name,
                                 :phone_number, :secondary_phone)
  end

  def new_profile_params
    params.require(:contractor_profile).permit(:address1, :address2, :zip, :emergency_contact_first_name,
                                               :emergency_contact_last_name, :emergency_contact_phone,
                                               :ssn, :dob, :driver_license)
  end
end