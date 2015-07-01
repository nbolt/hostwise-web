class BlastJob < ActiveJob::Base
  queue_as :default

  def perform booking
    ActiveRecord::Base.connection_pool.with_connection do
      if booking.job
        User.available_contractors(booking).each do |contractor|
          if contractor.can_claim_job?(booking.job)[:success]
            UserMailer.new_open_job(contractor, booking.job).then(:deliver) if contractor.settings(:new_open_job).email
            TwilioJob.perform_later("+1#{contractor.phone_number}", "New HostWise Job! $#{booking.job.payout(contractor)} in #{booking.property.city}, #{booking.property.zip} on #{booking.formatted_date}.") if contractor.settings(:new_open_job).sms
          end
        end
      end
    end
  end
end
