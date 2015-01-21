class HomeController < ApplicationController
  def index
    redirect_to subdomain: current_user.role.to_s, controller: 'home', action: 'index' if logged_in?
  end

  def signup
    redirect_to root_path if logged_in?
  end

  def signin
    redirect_to auth_path if logged_in?
  end

  def signout
    logout
    redirect_to root_path
  end

  def user
    render json: current_user.to_json(include: [:payments, properties: {methods: [:nickname, :short_address, :primary_photo, :full_address], include: [:bookings]}], methods: [:avatar, :name])
  end
end
