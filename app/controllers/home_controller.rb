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
    redirect_to root_url
  end

  def pricing
    render 'common/_pricing'
  end

  def faq
    render 'common/_faq'
  end

  def cost
    render json: PRICING.to_json
  end

  def man_hrs
    render json: MAN_HRS.to_json
  end

  def contact_email
    if logged_in?
      UserMailer.contact_email("Customer Support: #{params[:form][:description]}", current_user.email, params[:form][:message], current_user.first_name, current_user.last_name, current_user.phone_number).then(:deliver)
    else
      UserMailer.contact_email('Customer Support', params[:form][:email], params[:form][:message], params[:form][:first_name], params[:form][:last_name], params[:form][:phone_number]).then(:deliver)
    end
    render json: { success: true }
  end

  def user
    if logged_in?
      case current_user.role_cd
      when 1 # host
        render json: current_user.to_json(include: [:payments, properties: {methods: [:nickname, :short_address, :primary_photo, :full_address, :next_service_date], include: [:active_bookings, :future_bookings, :past_bookings]}], methods: [:avatar, :name, :role, :notification_settings])
      when 2 # contractor
        current_user.jobs.each {|j| j.current_user = current_user}
        render json: current_user.to_json(include: [:contractor_profile, :payments, :availability, jobs: {methods: [:payout_rounded, :payout_integer, :payout_fractional], include: {distribution_center: {methods: [:short_address]}, booking: {include: [property: {include: [user: {methods: [:name]}]}]}}}], methods: [:avatar, :name, :role, :notification_settings, :earnings, :unpaid])
      when 0 # admin
        render json: current_user.to_json(methods: [:avatar, :name, :role])
      end
    else
      render nothing: true
    end
  end
end
