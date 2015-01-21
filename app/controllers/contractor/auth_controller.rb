class Contractor::AuthController < ApplicationController
  layout 'contractor'
  before_filter :require_login

  private

  def require_login
    if !logged_in? || logged_in? && current_user.role != 'contractor'
      session[:return_to_url] = request.url if Config.save_return_to_url && request.get?
      self.send(Config.not_authenticated_action)
    end
  end

  def not_authenticated
    redirect_to '/signin'
  end

end
