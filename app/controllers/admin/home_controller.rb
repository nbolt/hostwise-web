class Admin::HomeController < Admin::AuthController
  def index
    render 'admin/index'
  end
end
