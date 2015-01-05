class Team::AuthController < ApplicationController

  def signin
    user = login(params[:form][:email], params[:form][:password])
    if user
      render json: { success: true, redirect_to: session[:return_to_url] || '/' }
    else
      user = User.where(email: params[:form][:email])[0]
      if user
        message = 'Invalid password'
      else
        message = 'Invalid email'
      end
      render json: { success: false, message: message }
    end
  end

  def phone_confirmed
    user = User.where(email: params[:email])[0]
    auto_login user
    render nothing: true
  end

  private

  def user_params
    params.require(:form).permit(:email, :password, :first_name, :last_name, :company, :role)
  end  

end
