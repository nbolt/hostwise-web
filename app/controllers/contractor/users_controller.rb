class Contractor::UsersController < Contractor::AuthController
  skip_before_filter :require_login, only: [:activate, :activated, :avatar]

  def update
    user = current_user
    if params[:step] == 'info'
      user.step = 'contractor_info'
      user.assign_attributes user_params
      if user.valid?
        user.save
        profile = user.contractor_profile
        edit_profile_params = params[:user][:contractor_profile]
        profile.address1 = edit_profile_params[:address1]
        profile.address2 = edit_profile_params[:address2]
        profile.zip = edit_profile_params[:zip]
        profile.emergency_contact_first_name = edit_profile_params[:emergency_contact_first_name]
        profile.emergency_contact_last_name = edit_profile_params[:emergency_contact_last_name]
        profile.emergency_contact_phone = edit_profile_params[:emergency_contact_phone]
        profile.assign_market
        if profile.save
          render json: { success: true }
        else
          render json: { success: false, message: profile.errors.full_messages[0] }
        end
      else
        render json: { success: false, message: user.errors.full_messages[0] }
      end
    elsif params[:step] == 'password'
      user.step = 'edit_password'
      unless params[:user][:current_password].present?
        render json: { success: false, message: 'Current password is required' }
        return
      end
      unless User.authenticate(user.email, params[:user][:current_password]).present?
        render json: { success: false, message: "Current password doesn't match" }
        return
      end
      params[:user].delete :current_password #clear unpermitted param
      user.assign_attributes(user_params)
      if user.save
        render json: { success: true }
      else
        render json: { success: false, message: user.errors.full_messages[0] }
      end
    elsif params[:step] == 'photo'
      user.avatars.build(photo: params[:file]) # need to background this
      if user.save
        render json: { success: true }
      else
        render json: { success: false, message: user.errors.full_messages[0] }
      end
    end
  end

  def activate
    if current_user && current_user.activation_state == 'active'
      respond_to do |format|
        format.html { render 'contractor/users/activate', layout: 'plain' }
        format.json { render json: current_user.to_json(include: [:contractor_profile], methods: [:avatar, :name, :role]) }
      end
    else
      user = User.load_from_activation_token(params[:id])
      if user
        respond_to do |format|
          format.html { render 'contractor/users/activate', layout: 'plain' }
          format.json { render json: user.to_json(include: [:contractor_profile], methods: [:avatar, :name, :role]) }
        end
      else
        not_authenticated
        return
      end
    end
  end

  def activated
    if current_user
      user = current_user
    else
      user = User.load_from_activation_token(params[:id])
    end
    user.assign_attributes user_params
    user.step = 'contractor_profile'
    user.phone_confirmed = true #hack for now

    if user.valid?
      profile = ContractorProfile.new
      profile.assign_attributes new_profile_params
      profile.position = :trainee
      profile.docusign_completed = true

      if profile.valid?
        profile.user = user
        profile.assign_market
        profile.save

        user.settings(:new_open_job).sms = true
        user.settings(:new_open_job).email = true
        user.settings(:job_claim_confirmation).sms = true
        user.settings(:job_claim_confirmation).email = true
        user.settings(:service_reminder).sms = true
        user.settings(:service_reminder).email = true

        user.save
        user.activate!
        auto_login user

        BackgroundCheckSubmissionJob.perform_later(user)
        UserMailer.contractor_profile_completed(user).then(:deliver)

        render json: { success: true }
      else
        render json: { success: false, message: profile.errors.full_messages[0] }
      end
    else
      render json: { success: false, message: user.errors.full_messages[0] }
    end
  end

  def avatar
    user = User.load_from_activation_token(params[:id])
    user.avatars.build(photo: params[:file])

    if user.save
      render json: { success: true }
    else
      render json: { success: false, message: user.errors.full_messages[0] }
    end
  end

  def deactivate
    current_user.deactivate!
    logout
    render json: { success: true }
  end

  def jobs_today
    timezone = Timezone::Zone.new :zone => current_user.contractor_profile.zone
    jobs = current_user.jobs.on_date(timezone.time Time.now).ordered(current_user)
    jobs.each {|j| j.current_user = current_user}
    render json: jobs.to_json(methods: [:payout_integer, :payout_fractional, :staging, :formatted_time], include: {distribution_center: {methods: [:full_address]}, contractors: {}, booking: {include: {property: {include: [user: {methods: [:name]}], methods: [:full_address]}}}})
  end

  private

  def user_params
    params.require(:user).permit(:email, :password, :password_confirmation, :first_name, :last_name,
                                 :phone_number, :secondary_phone)
  end

  def new_profile_params
    params.require(:contractor_profile).permit(:address1, :address2, :zip, :emergency_contact_first_name,
                                               :emergency_contact_last_name, :emergency_contact_phone,
                                               :ssn, :dob, :driver_license)
  end
end
