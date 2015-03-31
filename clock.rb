require 'clockwork'

require './config/boot'
require './config/environment'

module Clockwork
  url = Rails.application.routes.url_helpers
  
  handler do |job|
    case job
    when 'jobs:check_unclaimed'
      Job.where(status_cd: 0).each do |job|
        timezone = Timezone::Zone.new :zone => job.booking.property.zone
        time = timezone.time Time.now
        if time.hour == 17 && job.tomorrow?(time.to_date)
          UserMailer.generic_notification("Job for tomorrow not filled - #{job.id}", "Job ##{job.id} (#{job.booking.property.nickname}) for tomorrow has not been claimed by the required number of contractors - #{url.admin_job_url(job)}").then(:deliver)
        end
      end
    when 'jobs:check_no_shows'
      User.contractors.each do |contractor|
        timezone = Timezone::Zone.new :zone => contractor.contractor_profile.zone
        time = timezone.time Time.now
        jobs_today = contractor.jobs.on_date(time)
        jobs_today.each do |job|
          unless job.distribution || job.in_progress? || job.complete?
            priority = ContractorJobs.where(job_id: job.id, user_id: contractor.id)[0].priority
            staging = Rails.env.staging? && '[STAGING] ' || ''
            case priority
            when 1
              if time.hour == 10
                TwilioJob.perform_later("+1#{ENV['SUPPORT_NOTIFICATION_SMS']}", "#{staging}#{contractor.name} (#{contractor.id}) has not arrived at job ##{job.id} (#{job.booking.property.nickname})")
                UserMailer.generic_notification("Contractor has not arrived - #{contractor.name}", "#{contractor.name} (#{contractor.id}) has not arrived at job ##{job.id} (#{job.booking.property.nickname}) - #{url.admin_job_url(job)}").then(:deliver)
              end
            when 2
              if time.hour == 13
                TwilioJob.perform_later("+1#{ENV['SUPPORT_NOTIFICATION_SMS']}", "#{staging}#{contractor.name} (#{contractor.id}) has not arrived at job ##{job.id} (#{job.booking.property.nickname})")
                UserMailer.generic_notification("Contractor has not arrived - #{contractor.name}", "#{contractor.name} (#{contractor.id}) has not arrived at job ##{job.id} (#{job.booking.property.nickname}) - #{url.admin_job_url(job)}").then(:deliver)
              end
            when 3
              if time.hour == 14
                TwilioJob.perform_later("+1#{ENV['SUPPORT_NOTIFICATION_SMS']}", "#{staging}#{contractor.name} (#{contractor.id}) has not arrived at job ##{job.id} (#{job.booking.property.nickname})")
                UserMailer.generic_notification("Contractor has not arrived - #{contractor.name}", "#{contractor.name} (#{contractor.id}) has not arrived at job ##{job.id} (#{job.booking.property.nickname}) - #{url.admin_job_url(job)}").then(:deliver)
              end
            end
          end
        end
      end
    when 'jobs:check_timers'
      Job.where(status_cd: 5).each do |job|
        if job.booking.status != :couldnt_access && job.cant_access < Time.now.utc - 30.minutes
          job.booking.update_attribute :status_cd, 5
          job.booking.charge!
          job.contractors.each do |contractor|
            contractor.payouts.create(job_id: job.id, amount: job.payout(contractor) * 100)
          end

          staging = Rails.env.staging? && '[STAGING] ' || ''
          TwilioJob.perform_later("+1#{job.booking.property.phone_number}", "HostWise was unable to access your property. Having waited 30 minutes to resolve this issue, we must now move on to help another customer. A small charge of $#{PRICING['no_access_fee']} will be billed to your account in order to pay the housekeepers for their time.")
          TwilioJob.perform_later("+1#{ENV['SUPPORT_NOTIFICATION_SMS']}", "#{staging}#{job.primary_contractor.name} has waited for 30 min and is now leaving property #{job.booking.property.id}.")
        end
      end
    end
  end

  every(1.hour, 'jobs:check_no_shows', :at => '**:30')
  every(1.hour, 'jobs:check_unclaimed', :at => '**:00')
  every(10.minutes, 'jobs:check_timers')
end