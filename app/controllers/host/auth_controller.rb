class Host::AuthController < ApplicationController
  layout 'host'
  before_filter :require_login

  private

  def require_login
    if !logged_in? || logged_in? && current_user.role != :host
      session[:return_to_url] = request.url if Config.save_return_to_url && request.get?
      self.send(Config.not_authenticated_action)
    end
  end

  def not_authenticated
    redirect_to root_url + 'signin'
  end

end
