class BackgroundCheckNotificationJob < ActiveJob::Base
  queue_as :default

  def perform(order_id, order_status)
    begin
      ActiveRecord::Base.connection_pool.with_connection do
        background_check = BackgroundCheck.find_by_order_id order_id
        case order_status
          when 'pending'
            background_check.status = :pending
          when 'canceled'
            background_check.status = :canceled
          when 'ready'
            background_check.status = :ready
          when 'error'
            background_check.status = :error
          when 'partial'
            background_check.status = :partial
        end
        background_check.save
      end
    rescue Exception => e
      Rails.logger.error "Background check notification error: #{e}"
    end
  end
end
