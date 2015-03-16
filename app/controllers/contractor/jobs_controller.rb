class Contractor::JobsController < Contractor::AuthController

  expose(:job) { Job.find params[:id] }

  def index
    completed_jobs = Job.standard.past(current_user).count
    passed_quizzes = QuizStage.passed(current_user.contractor_profile)
    last_quiz = passed_quizzes.count > 0 ? passed_quizzes[0] : nil
    take_at = last_quiz.present? ? last_quiz.next : 0

    if completed_jobs == take_at
      redirect_to '/quiz'
    else
      case current_user.contractor_profile.position
        when :trainee
          redirect_to '/'
        when :fired
          redirect_to '/'
      end
    end
  end

  def show
    respond_to do |format|
      format.html do
        redirect_to '/' unless job.contractors.index current_user
      end
      format.json do
        job.current_user = current_user
        render json: job.to_json(methods: [:payout_integer, :payout_fractional], include: {contractors: {methods: [:name, :display_phone_number, :avatar]}, booking: {methods: [:cost], include: {services: {}, payment: {methods: :display}, property: {include: {property_photos: {}, user: {methods: [:avatar, :display_phone_number, :name]}}, methods: [:primary_photo, :full_address, :nickname, :property_type]}}}})
      end
    end
  end

  def begin
    job.update_attribute :status_cd, 2
    render json: { success: true }
  end

  def claim
    if current_user.claim_job job
      UserMailer.job_claim_confirmation(job, current_user).then(:deliver) if current_user.settings(:job_claim_confirmation).email
      TwilioJob.perform_later("+1#{current_user.phone_number}", 'You claimed a job') if current_user.settings(:job_claim_confirmation).sms
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
    job.complete!
    if current_user.contractor_profile.position == :trainee
      current_user.contractor_profile.update_attribute :position_cd, 2 if current_user.jobs.where(training:true).count == current_user.jobs.where(training:true,status_cd:3).count
    end
    if job.booking
      property = job.booking.property
      UserMailer.service_completed(job.booking).then(:deliver) if property.user.settings(:service_completion).email
      TwilioJob.perform_later("+1#{property.user.phone_number}", "Service completed at #{property.short_address}") if property.user.settings(:service_completion).sms
    end
    render json: { success: true, next_job: job.next_job(current_user).then(:id) }
  end

  def status
    timezone = Timezone::Zone.new :latlon => [job.booking.property.lat, job.booking.property.lng]
    if job.status == :completed
      render json: { success: true, status: 'completed' }
    elsif job.status == :in_progress
      render json: { success: true, status: 'in_progress' }
    elsif job.date == (timezone.time Time.now).to_date
      prev_job = job.previous_job current_user
      if prev_job
        if prev_job.status == :completed
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
    render json: checklist.to_json(methods: :checklist_settings)
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

end
