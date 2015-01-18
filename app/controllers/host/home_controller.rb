class Host::HomeController < Host::AuthController
  
  def index
    redirect_to '/dashboard'
  end

  def dashboard
    render 'host/index'
  end

end
