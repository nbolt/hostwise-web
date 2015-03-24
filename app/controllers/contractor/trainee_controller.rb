class Contractor::TraineeController < Contractor::AuthController

  def available_jobs
    jobs = Job.standard.future.scheduled.trainers.not_training.first_jobs.order('date').to_a.uniq{|job| job.date}
    render json: jobs[0..7].to_json(include: :booking)
  end

  def bgc
    render json: current_user.background_check
  end

  def claim_jobs
    if params[:jobs]
      jobs = params[:jobs].map {|j| Job.find j['job']}
      if jobs.find {|job| job.training}
        render json: { success: false }
      else
        jobs.each do |job|
          job.update_attribute :training, true
          job.contractors.push current_user
          ContractorJobs.where(job_id: job.id, user_id: current_user.id)[0].update_attribute :priority, 1
          distribution_job = job.primary_contractor.jobs.on_date(job.date).pickup[0]
          distribution_job.contractors.push current_user
        end
        render json: { success: true }
      end
    else
      render json: { success: false }
    end
  end

end
