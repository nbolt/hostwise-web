class NewJobs < ActiveJob::Base
  queue_as :default

  def perform contractor
    ActiveRecord::Base.connection_pool.with_connection do
      UserMailer.new_jobs(contractor).then(:deliver) if contractor.settings(:new_open_job).email
      TwilioJob.perform_later("+1#{contractor.phone_number}", "There are new HostWise jobs available in #{contractor.contractor_profile.market.name}.") if contractor.settings(:new_open_job).sms
    end
  end
end
