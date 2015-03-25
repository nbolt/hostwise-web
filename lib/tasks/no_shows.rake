namespace :jobs do
  task check_no_shows: :environment do
    User.contractors.each do |contractor|
      timezone = Timezone::Zone.new :zone => contractor.contractor_profile.zone
      time = timezone.time Time.now
      jobs_today = contractor.jobs.on_date(time)
      jobs_today.each do |job|
        unless job.distribution || job.in_progress? || job.complete?
          priority = ContractorJobs.where(job_id: job.id, user_id: contractor.id)[0].priority
          case priority
          when 1
            if time.hour == 10 && time.min == 30
              TwilioJob.perform_later("+1#{ENV['SUPPORT_NOTIFICATION_SMS']}", "#{contractor.name} (#{contractor.id}) has not arrived at job ##{job.id} (#{job.booking.property.nickname})")
              UserMailer.generic_notification("Contractor has not arrived - #{contractor.name}", "#{contractor.name} (#{contractor.id}) has not arrived at job ##{job.id} (#{job.booking.property.nickname}) - #{admin_job_url(job)}").then(:deliver)
            end
          when 2
            if time.hour == 13 && time.min == 30
              TwilioJob.perform_later("+1#{ENV['SUPPORT_NOTIFICATION_SMS']}", "#{contractor.name} (#{contractor.id}) has not arrived at job ##{job.id} (#{job.booking.property.nickname})")
              UserMailer.generic_notification("Contractor has not arrived - #{contractor.name}", "#{contractor.name} (#{contractor.id}) has not arrived at job ##{job.id} (#{job.booking.property.nickname}) - #{admin_job_url(job)}").then(:deliver)
            end
          when 3
            if time.hour == 14 && time.min == 30
              TwilioJob.perform_later("+1#{ENV['SUPPORT_NOTIFICATION_SMS']}", "#{contractor.name} (#{contractor.id}) has not arrived at job ##{job.id} (#{job.booking.property.nickname})")
              UserMailer.generic_notification("Contractor has not arrived - #{contractor.name}", "#{contractor.name} (#{contractor.id}) has not arrived at job ##{job.id} (#{job.booking.property.nickname}) - #{admin_job_url(job)}").then(:deliver)
            end
          end
        end
      end
    end
  end
end
