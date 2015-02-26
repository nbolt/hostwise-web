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
      case current_user.role_cd
      when 1 # host
        render json: current_user.to_json(include: [:payments, properties: {methods: [:nickname, :short_address, :primary_photo, :full_address, :next_service_date], include: [:bookings]}], methods: [:avatar, :name, :role, :notification_settings])
      when 2 # contractor
        render json: current_user.to_json(include: [:contractor_profile, :payments, :availability, jobs: {methods: [:payout_rounded, :payout_integer, :payout_fractional], include: [booking: {include: [property: {include: [user: {methods: [:name]}]}]}]}], methods: [:avatar, :name, :role, :notification_settings])
      when 0 # admin
        render json: current_user.to_json(methods: [:avatar, :name, :role])
      end
    else
      render nothing: true
    end
  end
end
