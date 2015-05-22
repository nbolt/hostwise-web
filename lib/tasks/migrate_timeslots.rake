namespace :migrate do
  task timeslots_and_linen_program: :environment do
    Booking.all.each {|booking| booking.update_attributes(linen_handling: :rental, timeslot_type: :flex)}

    Booking.active.each do |booking|
      booking.update_cost!
      booking.job.contractors.each do |contractor|
        Job.set_priorities contractor, booking.date unless booking.job.training && !ContractorJobs.where(user_id: contractor.id, job_id: booking.job.id)[0].primary
      end
    end
  end
end
