class Admin::AuthController < ApplicationController
  layout 'admin'
  before_filter :require_login

  def login_as
    user = User.where(id: params[:id])[0]
    auto_login user if user
    redirect_to '/'
  end

  private

  def require_login
    if !logged_in? || logged_in? && current_user.role != :admin
      session[:return_to_url] = request.url if Config.save_return_to_url && request.get?
      self.send(Config.not_authenticated_action)
    end
  end

  def not_authenticated
    redirect_to root_url + 'signin'
  end

end
