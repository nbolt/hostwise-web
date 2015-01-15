class UsersController < ApplicationController
  before_filter :require_login, except: [:show]

  def show
    render json: current_user.to_json(methods: [:avatar, :name])
  end

  def edit
    respond_to do |format|
      format.html
      format.json { render json: current_user.to_json(methods: [:avatar, :name]) }
    end
  end

  def update
    user = current_user
    if params[:step] == 'info'
      User.step = 'edit_info'
    elsif params[:step] == 'password'
      User.step = 'edit_password'
      unless params[:form][:current_password].present?
        render json: { success: false, message: 'Current password is required' }
        return
      end
      unless User.authenticate(user.email, params[:form][:current_password]).present?
        render json: { success: false, message: "Current password doesn't match" }
        return
      end
    end

    params[:form].delete :current_password #clear unpermitted param
    user.assign_attributes(user_params)
    if user.save
      render json: { success: true }
    else
      render json: { success: false, message: user.errors.full_messages[0] }
    end
  end

  private

  def user_params
    params.require(:form).permit(:email, :password, :password_confirmation, :first_name, :last_name, :phone_number)
  end
end
