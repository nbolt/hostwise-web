class Contractor::JobsController < Contractor::AuthController

  expose(:job) { Job.find params[:id] }

  def show
    respond_to do |format|
      format.html
      format.json { render json: job.to_json(include: {contractors: {methods: [:name, :display_phone_number]}, booking: {methods: [:cost], include: [:services, property: {include: {user: {methods: [:avatar, :display_phone_number, :name]}}, methods: [:primary_photo, :full_address]}]}}) }
    end
  end

  def claim
    if current_user.claim_job job
      render json: { success: true }
    else
      render json: { success: false }
    end
  end

  def drop
    if current_user.drop_job job
      render json: { success: true }
    else
      render json: { success: false }
    end
  end

  def complete
    job.update_attribute :status_cd, 3
    property = job.booking.property
    UserMailer.service_completed(property).then(:deliver) if property.user.settings(:service_completion).email
    TwilioJob.perform_later("+1#{property.user.phone_number}", "Service completed at #{property.short_address}") if property.user.settings(:service_completion).sms
    render json: { success: true }
  end

end
