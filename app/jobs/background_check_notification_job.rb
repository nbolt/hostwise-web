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
      end
    rescue Exception => e
      Rails.logger.error "Background check notification error: #{e}"
    end
  end
end
