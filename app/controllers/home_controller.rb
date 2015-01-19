class HomeController < ApplicationController
  layout 'default'

  def index
    redirect_to subdomain: current_user.role, controller: 'home', action: 'index' if logged_in?
  end

  def home
    redirect_to subdomain: 'www', controller: 'home', action: 'index'
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
