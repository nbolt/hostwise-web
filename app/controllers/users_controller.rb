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

  end

  private

  def user_params
    params.require(:form).permit(:email, :password, :password_confirmation, :first_name, :last_name, :phone_number)
  end
end
