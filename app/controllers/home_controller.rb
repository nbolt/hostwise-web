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

  def cost
    render json: PRICING.to_json
  end

  def user
    if logged_in?
      if current_user.host?
        render json: current_user.to_json(include: [:payments, properties: {methods: [:nickname, :short_address, :primary_photo, :full_address, :next_service_date], include: [:bookings]}], methods: [:avatar, :name, :role])
      elsif current_user.contractor?
        render json: current_user.to_json(include: [:contractor_profile, :payments, :availability, jobs: {include: [booking: {include: [property: {include: [user: {methods: [:name]}]}]}]}], methods: [:avatar, :name, :role, :notification_settings])
      elsif current_user.admin?
        render json: current_user.to_json(methods: [:avatar, :name, :role])
      end
    else
      render nothing: true
    end
  end
end
