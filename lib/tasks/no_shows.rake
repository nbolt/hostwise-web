namespace :jobs do
  task check_no_shows: :environment do
    User.contractors.each do |contractor|
      timezone = Timezone::Zone.new :zone => contractor.contractor_profile.zone
      time = timezone.time Time.now
      jobs_today = contractor.jobs.on_date(time)
      jobs_today.each do |job|
        unless job.distribution || job.complete?
          priority = ContractorJobs.where(job_id: job.id, user_id: contractor.id)[0].priority
          case priority
          when 1
            if time.hour == 10 && time.min == 30
              # send notifications
            end
          when 2
            if time.hour == 13 && time.min == 30
              # send notifications
            end
          when 3
            if time.hour == 14 && time.min == 30
              # send notifications
            end
          end
        end
      end
    end
  end
end
