class Admin::AuthController < ApplicationController

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

end
