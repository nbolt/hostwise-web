class DocusignNotificationJob < ActiveJob::Base
  queue_as :default

  def perform(user)
    begin
      ActiveRecord::Base.connection_pool.with_connection do
        # we will only received completed event notification from docusign (part of the api config)
        user.contractor_profile.docusign_completed = true
        user.contractor_profile.save
      end

      # submit background check once 1099 contract is signed
      BackgroundCheckSubmissionJob.perform_later(user)

    rescue Exception => e
      Rails.logger.error "Docusign notification error: #{e}"
    end
  end
end
