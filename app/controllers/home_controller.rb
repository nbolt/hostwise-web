class HomeController < ApplicationController
  def index
    if logged_in?
      if current_user.role == :admin || current_user.role == :super_mentor
        redirect_to subdomain: 'admin', controller: 'home', action: 'index'
      else
        redirect_to subdomain: current_user.role.to_s, controller: 'home', action: 'index'
      end
    end
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

  def linenandtowel
    render 'common/_linenandtowel'
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

  def stripe_recipient
    if current_user.chain(:contractor_profile, :stripe_recipient_id)
      recipient = Stripe::Account.retrieve current_user.contractor_profile.stripe_recipient_id
      render json: { success: true, recipient: recipient }
    else
      render json: { success: false }
    end
  end

  def user
    if logged_in?
      render json: current_user, serializer: HomeUserSerializer, root: :user
    else
      render nothing: true
    end
  end
end
