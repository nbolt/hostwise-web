class Contractor::TraineeController < Contractor::AuthController

  def available_jobs
    jobs = Job.standard.within_market(current_user.contractor_profile.market).future(current_user.contractor_profile.zone).scheduled.single.trainers.not_training.order('jobs.date')
    jobs = jobs - jobs.on_date(current_user.jobs.standard[0].date) if current_user.jobs.standard.first
    jobs = jobs.each {|job| job.current_user = current_user}
    jobs = jobs.reject {|job| job.previous_team_job}.uniq{|job| job.date}
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
          prev_payout = job.payout job.primary_contractor
          job.update_attribute :training, true
          job.contractors.push current_user
          ContractorJobs.where(job_id: job.id, user_id: current_user.id)[0].update_attribute :priority, 1
          distribution_job = job.primary_contractor.jobs.on_date(job.date).pickup[0]
          distribution_job.contractors.push current_user
          TwilioJob.perform_later("+1#{job.primary_contractor.phone_number}", "Your job on #{job.formatted_date} is now a mentor job. Payout has increased from $#{prev_payout} to $#{job.payout(job.primary_contractor)}!")
        end
        render json: { success: true }
      end
    else
      render json: { success: false }
    end
  end

end
