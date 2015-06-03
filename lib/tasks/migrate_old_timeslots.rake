namespace :migrate do
  task old_timeslots: :environment do
    bookings = []

    Booking.past.each do |booking|
      booking.job.contractors.each do |contractor|
        begin
          Job.organize_day contractor, booking.date
        rescue
          bookings.push booking.id
        end
      end
    end

    bookings.each do |id|
      print "#{id} .. "
      booking = Booking.find id
      booking.job.contractors.each do |contractor|
        Job.set_priorities contractor, booking.date, true unless contractor.jobs.standard.on_date(booking.date).count > 3 || (booking.job.training && !ContractorJobs.where(user_id: contractor.id, job_id: booking.job.id)[0].primary)
      end
    end
  end
end
