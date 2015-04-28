class Admin::HomeController < Admin::AuthController
  def index
    redirect_to '/dashboard'
  end
end
