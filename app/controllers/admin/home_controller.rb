class Admin::HomeController < Admin::AuthController
  def index
    redirect_to '/contractors'
  end
end
