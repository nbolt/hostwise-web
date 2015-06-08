class Api::AuthController < ApplicationController

  def login
    user = User.where(email: params[:email].gsub(' ', '+'))[0]
    if user && user.valid_password?(params[:password])
      render json: { token: user.auth_token, id: user.id }
    else
      render nothing: true, status: :unauthorized
    end
  end

end
