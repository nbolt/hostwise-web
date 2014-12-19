class AuthController < ApplicationController

  def signup
    case params[:stage]
    when 1
      user = User.where(email: params[:form][:email])[0]
      if user
        user.assign_attributes(user_params)
      else
        user = User.new(user_params)
      end
    when 2
      user = User.where(email: params[:form][:email])[0]
      user.assign_attributes(user_params)
    when 3
      parsed_number = params[:form][:phone_number].match(/(\d).*(\d).*(\d).*(\d).*(\d).*(\d).*(\d).*(\d).*(\d).*(\d)/)
      unless parsed_number[10]
        render json: { success: false, message: "Make sure you've entered your phone number in ten-digit format" }
        return
      end
      parsed_number = parsed_number[1..10].join
      user = User.where(email: params[:form][:email])[0]
      user.phone_number = parsed_number
      user.phone_confirmation = rand(1000..9999)
      TwilioJob.new.async.perform("+1#{user.phone_number}", "Welcome to Porter! You're confirmation code is: #{user.phone_confirmation}")
    when 4
      user = User.where(email: params[:form][:email])[0]
      if params[:form][:confirmation_code] == user.phone_confirmation
        user.update_attribute :phone_confirmed, true
      else
        render json: { success: false, message: "Confirmation code doesn't match" }
        return
      end
    end
    if user.save
      render json: { success: true }
    else
      render json: { success: false, message: user.errors.full_messages[0] }
    end
  end

  def signin
    user = login(params[:form][:email], params[:form][:password])
    if user
      render json: { success: true }
    else
      render json: { success: false, message: user.errors.full_messages[0] }
    end
  end

  def phone_confirmed
    user = User.where(email: params[:email])[0]
    auto_login user
    render nothing: true
  end

  private

  def user_params
    params.require(:form).permit(:email, :password, :first_name, :last_name, :company)
  end

end
