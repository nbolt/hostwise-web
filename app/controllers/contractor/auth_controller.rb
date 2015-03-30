class Contractor::AuthController < ApplicationController
  layout 'contractor'
  before_filter :require_login, :handle_trainees

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

  def handle_trainees
    if !request.headers['X-CSRF-Token'] && current_user
      if !current_user.contractor_profile && request.fullpath != '/users/activate'
        redirect_to '/users/activate'
      end
    end
  end

end
