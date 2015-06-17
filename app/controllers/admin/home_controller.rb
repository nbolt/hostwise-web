class Admin::HomeController < Admin::AuthController
  def index
    case current_user.role
    when :admin
      redirect_to '/dashboard'
    when :super_mentor
      redirect_to '/jobs'
    end
  end
end
