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
        distribution_job = current_user.jobs.build(distribution: true, status_cd: 1, date: job.date)
        if distribution_job.booking.services.index Service.where(name: 'linens')[0]
          distribution_job.king_beds = job.booking.property.king_beds
          distribution_job.queen_beds = job.booking.property.queen_beds
          distribution_job.full_beds = job.booking.property.full_beds
          distribution_job.twin_beds = job.booking.property.twin_beds
        end
        distribution_job.toiletries ||= 0
        distribution_job.booking.property.beds.times { distribution_job.toiletries += 1 } if distribution_job.booking.services.index Service.where(name: 'toiletries')[0]
        distribution_job.save
      end
      render json: { success: true }
    end
  end

end
