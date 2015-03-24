class BackgroundCheckNotificationJob < ActiveJob::Base
  queue_as :default

  def perform(order_id, status)
    begin
      ActiveRecord::Base.connection_pool.with_connection do
        background_check = BackgroundCheck.find_by_order_id order_id
        case status
          when 'pending'
            background_check.status = :pending
          when 'clear'
            background_check.status = :clear
          when 'consider'
            background_check.status = :consider
        end
        background_check.save

        unless background_check.status == :pending
          msg = "The background check result for #{background_check.user.first_name} #{background_check.user.last_name}: #{background_check.status.to_s.upcase}."
          msg += ' Further action is required.' if background_check.status == :consider
          UserMailer.generic_notification("Background Check - #{background_check.user.name}", msg).then(:deliver)
        end
      end
    rescue Exception => e
      Rails.logger.error "Background check notification error: #{e}"
    end
  end
end
