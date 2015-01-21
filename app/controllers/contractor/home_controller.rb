class Contractor::HomeController < Contractor::AuthController
  def index
    render 'contractor/index'
  end

  def faq
    render 'contractor/faq'
  end

  def help
    render 'contractor/help'
  end
end
