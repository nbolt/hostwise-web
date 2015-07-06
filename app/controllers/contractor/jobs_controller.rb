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
        if job.primary_contractor == current_user
          @kitchen_photo = Checklist.new.kitchen_photo
          @kitchen_photo.success_action_status = '201'

          @bedroom_photo = Checklist.new.bedroom_photo
          @bedroom_photo.success_action_status = '201'

          @bathroom_photo = Checklist.new.bathroom_photo
          @bathroom_photo.success_action_status = '201'
        end
        if !job.contractors.index current_user
          redirect_to '/'
        elsif job.distribution
          render 'distribution'
        end
      end
      format.json do
        job.current_user = current_user
        render json: job.to_json(methods: [:formatted_time, :payout, :payout_integer, :payout_fractional, :next_job, :prev_job, :cant_access_seconds_left, :man_hours, :primary, :toiletry_count, :is_last_job_of_day, :index_in_day, :king_bed_count, :twin_bed_count, :pillow_count, :bath_towel_count, :bath_mat_count, :hand_towel_count, :face_towel_count], include: {distribution_center: {methods: [:full_address, :full_address_encoded, :map_address]}, contractors: {methods: [:name, :display_phone_number, :avatar], include: {contractor_profile: {}}}, booking: {methods: [:cost], include: {services: {}, payment: {methods: :display}, property: {include: {property_photos: {}, user: {methods: [:avatar, :display_phone_number, :name]}}, methods: [:primary_photo, :full_address, :full_address_encoded, :map_address, :neighborhood, :nickname, :property_type, :property_size]}}}})
      end
    end
  end

  def begin
    if job.status == :open || job.status == :scheduled || job.status == :cant_access
      job.status_cd = 2
      job.save

      if params[:issue_resolved].present? # issue resolved
        staging = Rails.env.staging? && '[STAGING] ' || ''
        TwilioJob.perform_later("+1#{ENV['SUPPORT_NOTIFICATION_SMS']}", "#{staging}#{job.primary_contractor.name} has resolved the issue at property #{job.booking.property.id}.")
      else
        TwilioJob.perform_later("+1#{job.booking.property.phone_number}", "HostWise has arrived. Your housekeeper is #{job.primary_contractor.name} and can be reached at #{job.primary_contractor.display_phone_number}.") if job.booking.property.user.settings(:porter_arrived).sms
      end
    end

    render json: { success: true, status_cd: job.status_cd }
  end

  def done
    job.update_attribute :status_cd, 3 if job.status == :scheduled
    render json: { success: true, next_job: job.next_job(current_user).then(:id) }
  end

  def cant_access
    unless job.status == :cant_access
      job.update_attributes(status_cd: 5, cant_access: Time.now)
      staging = Rails.env.staging? && '[STAGING] ' || ''
      if params[:property_occupied].present? # property occupied
        TwilioJob.perform_later("+1#{job.booking.property.phone_number}", "HostWise has arrived at #{job.booking.property.full_address}. There are still guests occupying the property. Please call the housekeeper ASAP at #{job.primary_contractor.display_phone_number} to resolve this issue.")
        TwilioJob.perform_later("+1#{ENV['SUPPORT_NOTIFICATION_SMS']}", "#{staging}#{job.primary_contractor.name} has arrived at property #{job.booking.property.id} and guests are still occupying the property. This is for job ##{job.id}.")
      else # can't access
        TwilioJob.perform_later("+1#{job.booking.property.phone_number}", "HostWise has arrived at #{job.booking.property.full_address}. We are having trouble accessing the property. Please call the housekeeper ASAP at #{job.primary_contractor.display_phone_number} to resolve this issue.")
        TwilioJob.perform_later("+1#{ENV['SUPPORT_NOTIFICATION_SMS']}", "#{staging}#{job.primary_contractor.name} has arrived at property #{job.booking.property.id} and cannot access. This is for job ##{job.id}.")
      end
    end
    render json: { success: true, status_cd: job.status_cd, seconds_left: job.cant_access_seconds_left }
  end

  def timer_finished
    unless job.booking.status == :couldnt_access
      job.booking.update_attribute :status_cd, 5
      job.pay_contractors!
      staging = Rails.env.staging? && '[STAGING] ' || ''
      TwilioJob.perform_later("+1#{ENV['SUPPORT_NOTIFICATION_SMS']}", "#{staging}#{job.primary_contractor.name} was unable to access property ##{job.booking.property.id} and the 30m timer has passed. They are now either leaving the property or have forgotten to notify us they've gotten in. This is for job ##{job.id}.")
    end
    render json: { success: true }
  end

  def call
    staging = Rails.env.staging? && '[STAGING] ' || ''
    TwilioJob.perform_later("+1#{ENV['SUPPORT_NOTIFICATION_SMS']}", "#{staging}#{job.primary_contractor.name} has attempted to call customer #{job.booking.property.user.id} regarding property #{job.booking.property.id} for job ##{job.id}.")
    render json: { success: true }
  end

  def sms
    staging = Rails.env.staging? && '[STAGING] ' || ''
    TwilioJob.perform_later("+1#{ENV['SUPPORT_NOTIFICATION_SMS']}", "#{staging}#{job.primary_contractor.name} has attempted to message customer #{job.booking.property.user.id} regarding property #{job.booking.property.id} for job ##{job.id}.")
    render json: { success: true }
  end

  def claim
    rsp = current_user.claim_job job
    if rsp[:success]
      UserMailer.job_claim_confirmation(job, current_user).then(:deliver) if current_user.settings(:job_claim_confirmation).email
      TwilioJob.perform_later("+1#{current_user.phone_number}", "Success! You have claimed the HostWise job for #{job.booking.property.short_address} on #{job.formatted_date}.") if current_user.settings(:job_claim_confirmation).sms
      render json: { success: true }
    else
      render json: { success: false, message: rsp[:message] }
    end
  end

  def drop
    if current_user.drop_job job
      if job.booking.next_day_cancellation
        current_user.update_attribute(:last_minute_cancellation_count, current_user.last_minute_cancellation_count + 1)
        body = "#{current_user.name} (#{current_user.id}) just made a last minute cancellation for job <a href='http://admin.hostwise.com/jobs/#{job.id}'>#{job.id}</a>. #{current_user.name} has now made #{current_user.last_minute_cancellation_count} last minute cancellations."
        UserMailer.generic_notification("Last Minute Contractor Cancellation - #{current_user.name}", body).then(:deliver)
      end
      unless current_user.contractor_profile.trainee?
        User.available_contractors(job.booking).each do |contractor|
          UserMailer.new_open_job(contractor, job).then(:deliver) if contractor.settings(:new_open_job).email
          TwilioJob.perform_later("+1#{contractor.phone_number}", "New HostWise Job! $#{job.payout(contractor)} in #{job.booking.property.city}, #{job.booking.property.zip} on #{job.booking.formatted_date}.") if contractor.settings(:new_open_job).sms && job.date <= Date.today + 2.weeks
        end
      end
      render json: { success: true }
    else
      render json: { success: false }
    end
  end

  def complete
    unless job.status == :completed
      job.complete!

      if job.booking
        property = job.booking.property
        checklist_photos = []
        checklist_photos << job.checklist.kitchen_photo.url << job.checklist.bedroom_photo.url << job.checklist.bathroom_photo.url

        if property.user.settings(:service_completion).sms
          TwilioJob.perform_later("+1#{property.phone_number}", "Your property at #{property.full_address} has been cleaned and is ready for your next check in!")
          TwilioJob.perform_later("+1#{property.phone_number}", '', checklist_photos)
        end

        if property.user.first_service?
          body = "Job: #{job.id} - Property: #{property.full_address} - Customer: #{property.user.name}"
          UserMailer.generic_notification("First Service - #{property.user.name}", body).then(:deliver)
        end

        king_sheets  = job.checklist.checklist_settings[:inventory_count]['king_sheets']
        twin_sheets  = job.checklist.checklist_settings[:inventory_count]['twin_sheets']
        total_sheets = king_sheets + twin_sheets
        job.booking.property.update_attribute :linen_count, job.booking.property.linen_count + job.soiled_pickup_count - total_sheets
        job.booking.property.update_attribute :linen_count, 0 if property.linen_count < 0
        job.checklist.settings(:inventory_count).update_attributes(mismatch: true) if job.soiled_pickup_count != total_sheets
      end
    end
    render json: { success: true, next_job: job.next_job(current_user).then(:id), status_cd: job.status_cd }
  end

  def status
    if job.distribution_center
      timezone = Timezone::Zone.new :zone => job.distribution_center.zone
    else
      timezone = Timezone::Zone.new :zone => job.booking.property.zone
    end

    if job.status == :completed
      render json: { success: true, status: 'completed' }
    elsif job.status == :in_progress
      render json: { success: true, status: 'in_progress' }
    elsif job.status == :cant_access
      render json: { success: true, status: 'cant_access' }
    elsif job.date == (timezone.time Time.now).to_date
      prev_job = job.prev_job current_user
      if prev_job
        if prev_job.status == :completed || (prev_job.status == :cant_access && prev_job.cant_access_seconds_left == 0)
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
    checklist = ContractorJobs.where(job_id: params[:job_id], user_id: params[:contractor_id])[0].then(:checklist)
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
      contractor_photo = checklist.contractor_photos.create(photo: params[:file])
      job = Job.find_by_id(params[:job_id])
      staging = Rails.env.staging? && '[STAGING] ' || ''

      TwilioJob.perform_later("+1#{job.booking.property.phone_number}", "HostWise has found damage at #{job.booking.property.full_address}")
      TwilioJob.perform_later("+1#{job.booking.property.phone_number}", '', [contractor_photo.photo.url])
      TwilioJob.perform_later("+1#{ENV['SUPPORT_NOTIFICATION_SMS']}", "#{staging}#{job.primary_contractor.name} has found damage at property #{job.booking.property.id}.", [contractor_photo.photo.url])

      render json: { success: true, contractor_photos: checklist.contractor_photos }
    else
      render json: { success: false }
    end
  end

  def snap_photo
    ProcessContractorPhotoJob.perform_later(params[:key], params[:checklist_id], params[:room])
    render json: { success: true, url: "https://s3-#{ENV['S3_BUCKET']}.amazonaws.com/hostwise-#{Rails.env}/#{params[:key]}" }
  end

  def snap_photos
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
