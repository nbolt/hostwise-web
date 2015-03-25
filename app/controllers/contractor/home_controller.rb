class Contractor::HomeController < Contractor::AuthController
  def index
    if current_user.contractor_profile.position == :trainee && current_user.show_quiz
      redirect_to '/quiz'
      return
    end

    case current_user.contractor_profile.position
      when :trainee
        if current_user.jobs.count > 2
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
