class Contractor::HomeController < Contractor::AuthController
  def index
    case current_user.status
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

  def faq
    render 'contractor/faq'
  end

  def help
    render 'contractor/help'
  end
end
