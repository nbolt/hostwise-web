class Admin::HomeController < Admin::AuthController
  def index
    redirect_to '/bookings'
  end
end
