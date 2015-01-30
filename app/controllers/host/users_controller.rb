class Host::UsersController < Host::AuthController
  def update
    user = current_user
    if params[:step] == 'info'
      user.step = 'edit_info'
      user.assign_attributes(user_params)
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
    elsif params[:step] == 'photo'
      user.avatars.build(photo: params[:file]) # need to background this
    end

    if user.save
      render json: { success: true }
    else
      render json: { success: false, message: user.errors.full_messages[0] }
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

  def deactivate
    current_user.deactivate!
    logout
    render json: { success: true }
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name, :phone_number)
  end
end
