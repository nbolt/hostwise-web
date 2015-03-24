class Contractor::JobsController < Contractor::AuthController

  expose(:job) { Job.find params[:id] }

  def index
    if current_user.contractor_profile.position == :contractor && current_user.show_quiz
      redirect_to '/quiz'
      return
    end

    case current_user.contractor_profile.position
      when :trainee
        redirect_to '/'
      when :fired
        redirect_to '/'
    end
  end

  def show
    respond_to do |format|
      format.html do
        if !job.contractors.index current_user
          redirect_to '/'
        elsif job.distribution
          render 'distribution'
        end
      end
      format.json do
        job.current_user = current_user
        render json: job.to_json(methods: [:payout, :payout_integer, :payout_fractional, :next_job, :cant_access_seconds_left, :man_hours, :primary], include: {distribution_center: {methods: [:full_address]}, contractors: {methods: [:name, :display_phone_number, :avatar]}, booking: {methods: [:cost], include: {services: {}, payment: {methods: :display}, property: {include: {property_photos: {}, user: {methods: [:avatar, :display_phone_number, :name]}}, methods: [:primary_photo, :full_address, :nickname, :property_type]}}}})
      end
    end
  end

  def begin
    if job.status == :scheduled || job.status == :cant_access
      job.update_attribute :status_cd, 2

      if params[:issue_resolved].present? # issue resolved 
        TwilioJob.perform_later("+1#{ENV['SUPPORT_NOTIFICATION_SMS']}", "#{job.primary_contractor.name} has resolved the issue at property #{job.booking.property.id}.")
      else
        TwilioJob.perform_later("+1#{job.booking.property.phone_number}", "HostWise has arrived at #{job.booking.property.full_address}") if job.booking.property.user.settings(:porter_arrived).sms
      end
    end

    render json: { success: true, status_cd: job.status_cd }
  end

  def done
    job.update_attribute :status_cd, 3 if job.status == :scheduled
    next_job = job.next_job(current_user)

    if job.status == :completed && next_job
      TwilioJob.perform_later("+1#{next_job.booking.property.phone_number}", "HostWise is on the way to clean #{next_job.booking.property.full_address}. We will contact you when we arrive.") if next_job.booking.property.user.settings(:porter_en_route).sms
    end

    render json: { success: true, next_job: next_job.then(:id) }
  end

  def cant_access
    unless job.status == :cant_access
      job.update_attributes(status_cd: 5, cant_access: Time.now)

      if params[:property_occupied].present? #property occupied
        TwilioJob.perform_later("+1#{job.booking.property.phone_number}", "HostWise has arrived at #{job.booking.property.full_address} but there are still guests occupying the property. Please call the housekeeper ASAP at #{job.primary_contractor.display_phone_number} to resolve this issue.")
        TwilioJob.perform_later("+1#{ENV['SUPPORT_NOTIFICATION_SMS']}", "#{job.primary_contractor.name} has arrived at property #{job.booking.property.id} and guests are still occupying the property.")
      else #can't access
        TwilioJob.perform_later("+1#{job.booking.property.phone_number}", "HostWise has arrived at #{job.booking.property.full_address} but we are having trouble accessing the property. Please call the housekeeper ASAP at #{job.primary_contractor.display_phone_number} to resolve this issue.")
        TwilioJob.perform_later("+1#{ENV['SUPPORT_NOTIFICATION_SMS']}", "#{job.primary_contractor.name} has arrived at property #{job.booking.property.id} and cannot access.")
      end
    end
    render json: { success: true, status_cd: job.status_cd, seconds_left: job.cant_access_seconds_left }
  end

  def timer_finished
    unless job.booking.status == :couldnt_access
      job.booking.update_attribute :status_cd, 5
      job.booking.charge!
      job.contractors.each do |contractor|
        contractor.payouts.create(job_id: job.id, amount: job.payout(contractor) * 100)
      end

      TwilioJob.perform_later("+1#{job.booking.property.phone_number}", "HostWise was unable to access your property. Having waited 30 minutes to resolve this issue, we must now move on to help another customer. A small charge of $#{PRICING['no_access_fee']} will be billed to your account in order to pay the housekeepers for their time.")
      TwilioJob.perform_later("+1#{ENV['SUPPORT_NOTIFICATION_SMS']}", "#{job.primary_contractor.name} has waited for 30 min and is now leaving property #{job.booking.property.id}.")
    end
    render json: { success: true }
  end

  def claim
    if current_user.claim_job job
      UserMailer.job_claim_confirmation(job, current_user).then(:deliver) if current_user.settings(:job_claim_confirmation).email
      TwilioJob.perform_later("+1#{current_user.phone_number}", "Success! You have claimed the HostWise job for #{job.booking.property.short_address} on #{job.formatted_date}.") if current_user.settings(:job_claim_confirmation).sms
      render json: { success: true }
    else
      render json: { success: false, message: "Oops! Looks like you can't claim this job." }
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
    unless job.status == :completed
      job.complete!
      if current_user.contractor_profile.position == :trainee
        current_user.contractor_profile.update_attribute :position_cd, 2 if current_user.jobs.where(training:true).count == current_user.jobs.where(training:true,status_cd:3).count
      end
      if job.booking
        property = job.booking.property
        checklist_photos = []
        checklist_photos << job.checklist.kitchen_photo.url << job.checklist.bedroom_photo.url << job.checklist.bathroom_photo.url
        UserMailer.service_completed(job.booking).then(:deliver) if property.user.settings(:service_completion).email
        TwilioJob.perform_later("+1#{property.phone_number}", "Your property at #{property.full_address} has been cleaned and is ready for your next check in!", checklist_photos) if property.user.settings(:service_completion).sms
      end
    end
    render json: { success: true, next_job: job.next_job(current_user).then(:id), status_cd: job.status_cd }
  end

  def status
    if job.distribution_center
      timezone = Timezone::Zone.new :latlon => [job.distribution_center.lat, job.distribution_center.lng]
    else
      timezone = Timezone::Zone.new :latlon => [job.booking.property.lat, job.booking.property.lng]
    end

    if job.status == :completed
      render json: { success: true, status: 'completed' }
    elsif job.status == :in_progress
      render json: { success: true, status: 'in_progress' }
    elsif job.status == :cant_access
      render json: { success: true, status: 'cant_access' }
    elsif job.date == (timezone.time Time.now).to_date
      prev_job = job.previous_job current_user
      if prev_job
        if prev_job.status == :completed || prev_job.status == :cant_access
          render json: { success: true, status: 'active' }
        else
          render json: { success: true, status: 'blocked', blocker: 'prev_job' }
        end
      else
        render json: { success: true, status: 'active' }
      end
    else
      render json: { success: true, status: 'blocked', blocker: 'not_today' }
    end
  end

  def checklist
    checklist = ContractorJobs.where(job_id: params[:job_id], user_id: params[:contractor_id])[0].checklist
    if checklist
      render json: checklist.to_json(methods: :checklist_settings, include: :contractor_photos)
    else
      render nothing: true
    end
  end

  def checklist_update
    checklist = ContractorJobs.where(job_id: params[:job_id], user_id: params[:contractor_id])[0].checklist
    case params[:type]
      when 'setting'
        checklist.settings(params[:category].to_sym).send("#{params[:item]}=", params[:value])
        checklist.save
    end
    render json: { success: true }
  end

  def damage_photo
    checklist = ContractorJobs.where(job_id: params[:job_id], user_id: params[:contractor_id])[0].checklist

    if params[:file]
      photo = checklist.contractor_photos.create(photo: params[:file])
      render json: { success: true, contractor_photos: checklist.contractor_photos }
    else
      render json: { success: false }
    end
  end

  def snap_photo
    checklist = ContractorJobs.where(job_id: params[:job_id], user_id: params[:contractor_id])[0].checklist

    if params[:file]
      checklist.send "#{params[:room]}_photo=", params[:file]
      if checklist.save
        render json: { success: true, photo: checklist.send("#{params[:room]}_photo").as_json["#{params[:room]}_photo".to_sym] }
      else
        render json: { success: false }
      end
    else
      render json: { success: false }
    end
  end

end
