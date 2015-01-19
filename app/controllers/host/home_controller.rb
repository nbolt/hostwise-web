class Host::HomeController < Host::AuthController

  def index
    render 'host/index'
  end

end
