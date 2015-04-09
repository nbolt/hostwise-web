class Admin::ContractorsController < Admin::AuthController
  def index
    respond_to do |format|
      format.html
      format.json { render json: User.contractors.to_json(include: {background_check: {methods: [:status]}, contractor_profile: {methods: [:position, :display_position]}}, methods: [:name, :avatar, :next_job_date, :completed_jobs, :display_phone_number, :earnings]) }# why methods dont work?
    end
  end

  def signup
    user = User.new(user_params)
    temp_pwd = rand(1000..9999)
    user.password = temp_pwd
    user.password_confirmation = temp_pwd
    user.role = :contractor
    user.step = 'contractor_info'

    if user.save
      UserMailer.contractor_welcome_email(user, activate_url(user.activation_token)).then(:deliver)

      render json: { success: true }
    else
      render json: { success: false, message: user.errors.full_messages[0] }
    end
  end

  def edit
    respond_to do |format|
      format.html
      format.json { render json: User.find_by_id(params[:id]).to_json(include: [:background_check, contractor_profile: {methods: [:position, :ssn, :driver_license, :current_position, :test_session_completed]}], methods: [:name, :avatar]) }

      @contractor = User.find_by_id(params[:id])


    end
  end

  def update
    user = User.find_by_id params[:id]

    if params[:status].present?
      # if user.contractor_profile.position == :trainee && user.jobs.training.not_complete.count > 0
      #   render json: { success: false, message: 'Pending training jobs' }
      #   return
      # end

      UserMailer.contractor_hired_email(user).then(:deliver) if user.contractor_profile.position == :trainee && params[:status].downcase.to_sym == :contractor
      UserMailer.mentor_promotion_email(user).then(:deliver) if user.contractor_profile.position == :contractor && params[:status].downcase.to_sym == :trainer

      params[:status] = case params[:status].downcase
                          when 'fired'
                            'fired'
                          when 'applicant'
                            'trainee'
                          when 'contractor'
                            'contractor'
                          when 'mentor'
                            'trainer'
                        end

      user.contractor_profile.position = params[:status].downcase.to_sym
      user.contractor_profile.save
      render json: { success: true }
    else
      user.assign_attributes contractor_params
      user.step = 'contractor_info'

      if user.valid?
        user.save
        contractor_profile_params = params[:contractor][:contractor_profile]
        profile = user.contractor_profile
        profile.address1 = contractor_profile_params[:address1]
        profile.address2 = contractor_profile_params[:address2]
        profile.zip = contractor_profile_params[:zip]
        profile.emergency_contact_first_name = contractor_profile_params[:emergency_contact_first_name]
        profile.emergency_contact_last_name = contractor_profile_params[:emergency_contact_last_name]
        profile.emergency_contact_phone = contractor_profile_params[:emergency_contact_phone]

        if profile.valid?
          profile.save
          render json: { success: true }
        else
          render json: { success: false, message: profile.errors.full_messages[0] }
        end
      else
        render json: { success: false, message: user.errors.full_messages[0] }
      end
    end
  end

  def deactivate
    User.find_by_id(params[:id]).deactivate!
    render json: { success: true }
  end

  def reactivate
    User.find_by_id(params[:id]).reactivate!
    render json: { success: true }
  end

  def delete
    User.find_by_id(params[:id]).destroy
    render json: { success: true }
  end

  def complete_contract
    user = User.find_by_id(params[:id])
    user.contractor_profile.docusign_completed = true
    user.contractor_profile.save

    BackgroundCheckSubmissionJob.perform_later(user)
    render json: { success: true }
  end

  def background_check
    user = User.find_by_id(params[:id])
    user.background_check.status_cd = params[:status].to_i
    user.background_check.save

    if user.background_check.clear?
      UserMailer.background_check_verified(user).then(:deliver)
    elsif user.background_check.rejected?
      UserMailer.background_check_failed(user).then(:deliver)
      user.deactivate!
    end
    render json: { success: true }
  end

  private

  def user_params
    params.require(:form).permit(:email, :password, :password_confirmation,
                                 :first_name, :last_name, :company, :phone_number)
  end

  def contractor_params
    params.require(:contractor).permit(:email, :first_name, :last_name, :phone_number, :secondary_phone)
  end
end
