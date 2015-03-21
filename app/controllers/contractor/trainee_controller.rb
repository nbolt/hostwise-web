class Contractor::TraineeController < Contractor::AuthController
  
  def available_jobs
    jobs = Job.standard.future.trainers.first_jobs.order('date').to_a.uniq{|job| job.date}
    render json: jobs[0..7].to_json(include: :booking)
  end

  def claim_jobs
    jobs = params[:jobs].map {|j| Job.find j['job']}
    if jobs.find {|job| job.training}
      render json: { success: false }
    else
      jobs.each do |job|
        job.update_attribute :training, true
        job.contractors.push current_user
        primary_contractor = ContractorJobs.where(job_id: job.id, primary: true)[0].user
        distribution_job = primary_contractor.jobs.on_date(job.date).pickup[0]
        distribution_job.contractors.push current_user
      end
      render json: { success: true }
    end
  end

end
