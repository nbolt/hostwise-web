class Contractor::HomeController < Contractor::AuthController
  def index
    case current_user.contractor_profile.position
    when :trainee
      if current_user.jobs[0]
        render 'contractor/trainee_schedule'
      else
        render 'contractor/trainee'
      end
    else
      render 'contractor/index'
    end
  end

  def contact
    render 'common/_contact'
  end
end
