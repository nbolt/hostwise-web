class AuthController < ApplicationController

  def auth
    if logged_in?
      redirect_to subdomain: current_user.role.to_s, controller: 'home', action: 'index'
    else
      redirect_to '/signin'
    end
  end

  def signup
    case params[:stage]
    when 1
      user = User.where(email: params[:form][:email])[0]
      if user
        if user.phone_confirmed
          render json: { success: false, message: 'Account already exists' }
          return
        else
          user.step = 'step1'
          user.assign_attributes(user_params)
        end
      else
        user = User.new(user_params)
        user.role = :host
        user.step = 'step1'
      end
      if user.save
        render json: { success: true }
      else
        render json: { success: false, message: user.errors.full_messages[0] }
      end
    when 2
      user = User.where(email: params[:form][:email])[0]
      user.step = 'step2'
      user.assign_attributes(user_params)
      user.phone_confirmation = rand(1000..9999)
      if user.save
        TwilioJob.perform_later("+1#{user.phone_number}", "Welcome to Porter! You're confirmation code is: #{user.phone_confirmation}")
        UserMailer.welcome(user).then(:deliver)
        render json: { success: true }
      else
        render json: { success: false, message: user.errors.full_messages[0] }
      end
    when 3
      user = User.where(email: params[:form][:email])[0]
      if params[:form][:confirmation_code] == user.phone_confirmation
        user.update_attribute :phone_confirmed, true
        render json: { success: true }
      else
        render json: { success: false, message: "Confirmation code doesn't match" }
      end
    end
  end

  def signin
    user = User.where(email: params[:form][:email])[0]
    if user && !user.phone_confirmed
      render json: { success: false, message: "Email not found" }
    else
      user = login(params[:form][:email], params[:form][:password], params[:form][:remember])
      if user
        render json: { success: true, redirect_to: session[:return_to_url] || auth_path }
      else
        user = User.where(email: params[:form][:email])[0]
        if user
          message = 'Invalid password'
        else
          message = 'Email not found'
        end
        render json: { success: false, message: message }
      end
    end
  end

  def phone_confirmed
    user = User.where(email: params[:email])[0]
    auto_login user
    render nothing: true
  end

  private

  def user_params
    params.require(:form).permit(:email, :password, :password_confirmation,
                                 :first_name, :last_name, :company, :phone_number)
  end

end
