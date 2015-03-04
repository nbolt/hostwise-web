class PasswordResetsController < ApplicationController
  skip_before_filter :require_login

  def create
    user = User.find_by_email(params[:form][:email])
    if user
      user.generate_reset_password_token!
      UserMailer.reset_password_email(user, "http://www.hostwise.com#{edit_password_reset_url(user.reset_password_token)}").then(:deliver)
      render json: { success: true, message: 'Instructions have been sent to your email.' }
    else
      render json: { success: false, message: "Sorry! We're not able to locate your email." }
    end
  end

  def edit
    user = User.load_from_reset_password_token(params[:id])
    if user.blank?
      not_authenticated
      return
    end
  end

  def update
    token = params[:id]
    user = User.load_from_reset_password_token(token)

    if user
      user.password_confirmation = params[:form][:password_confirmation]
      if user.password_confirmation == params[:form][:password]
        if user.change_password!(params[:form][:password]) #clear the temporary token and update the password
          auto_login user
          render json: { success: true, redirect_to: root_path }
        else
          render json: { success: false, message: user.errors.full_messages[0] }
        end
      else
        render json: { success: false, message: "Password confirmation doesn't match Password" }
      end
    else
      render json: { success: false, message: "Sorry! We're not able to locate your account." }
    end
  end
end
