class Host::HomeController < Host::AuthController

  def index
    if current_user.properties.empty?
      redirect_to properties_first_path
    else
      render 'host/index'
    end
  end

  def faq
    render 'host/faq'
  end

  def pricing
    render 'host/pricing'
  end

  def help
    render 'host/help'
  end
end
