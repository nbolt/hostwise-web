class Api::UsersController < ApplicationController

  before_filter :authenticate

  expose(:user) do
    user = User.find params[:id]
    user if user.auth_token == params[:token]
  end

  def show
    render json: user.as_json
  end

  private

  def authenticate
    unless user
      render json: { success: false }, status: :unauthorized
      return
    end
  end

end
