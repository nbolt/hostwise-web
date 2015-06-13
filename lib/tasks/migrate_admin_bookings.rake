namespace :migrate do
  task admin_bookings: :environment do
    User.contractors.each do |contractor|
      contractor.jobs.group_by(&:date).each do |date, jobs|
        begin
          Job.organize_day contractor, date
        rescue
          jobs.select{|job| if job.booking then job.booking.timeslot_type_cd == 0 end}.compact.each {|job| job.booking.update_attribute :admin, true}
        end
      end
    end
  end
end
