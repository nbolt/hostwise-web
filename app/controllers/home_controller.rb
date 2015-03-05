class HomeController < ApplicationController
  before_filter do
    redirect_to "#{request.protocol}#{request.domain}:#{request.port}#{request.fullpath}" if !logged_in? && !request.subdomain.empty? && request.subdomain != 'www'
  end

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
    redirect_to "#{request.protocol}#{request.domain}:#{request.port}"
  end

  def cost
    render json: PRICING.to_json
  end

  def contact_email
    UserMailer.contact_email(params[:form][:email], params[:form][:message], params[:form][:first_name], params[:form][:last_name], params[:form][:phone_number]).then(:deliver)
    render json: { success: true }
  end

  def user
    if logged_in?
      case current_user.role_cd
      when 1 # host
        render json: current_user.to_json(include: [:payments, properties: {methods: [:nickname, :short_address, :primary_photo, :full_address, :next_service_date], include: [:active_bookings]}], methods: [:avatar, :name, :role, :notification_settings])
      when 2 # contractor
        render json: current_user.to_json(include: [:contractor_profile, :payments, :availability, jobs: {methods: [:payout_rounded, :payout_integer, :payout_fractional], include: [booking: {include: [property: {include: [user: {methods: [:name]}]}]}]}], methods: [:avatar, :name, :role, :notification_settings, :earnings, :unpaid])
      when 0 # admin
        render json: current_user.to_json(methods: [:avatar, :name, :role])
      end
    else
      render nothing: true
    end
  end
end
