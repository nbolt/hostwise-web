class Admin::HomeController < Admin::AuthController
  def index
    redirect_to '/jobs'
  end
end
