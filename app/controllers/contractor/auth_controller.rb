class Contractor::AuthController < ApplicationController
  layout 'contractor'
  before_filter :require_login, :handle_incomplete_profiles

  private

  def require_login
    if !logged_in? || logged_in? && current_user.role != :contractor
      session[:return_to_url] = request.url if Config.save_return_to_url && request.get?
      self.send(Config.not_authenticated_action)
    end
  end

  def not_authenticated
    redirect_to root_url + 'signin'
  end

  def handle_incomplete_profiles
    if current_user && !request.headers['X-CSRF-Token']
      if !current_user.contractor_profile && request.fullpath != '/users/activate'
        redirect_to '/users/activate'
      elsif current_user.payments.empty? && request.fullpath != '/payments' && request.fullpath != '/users/activate'
        redirect_to '/payments'
      end
    end
  end

end
