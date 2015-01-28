class BackgroundCheckSubmissionJob < ActiveJob::Base
  queue_as :default

  def perform(user, xml)
    begin
      if Rails.env.staging? || Rails.env.production?
        response = RestClient.post 'https://rcr.instascreen.net/send/interchange', xml, content_type: 'text/xml'
        if response.code == 200
          doc = Nokogiri::XML response.body
          order_id = doc.xpath('//OrderId').text
          ActiveRecord::Base.connection_pool.with_connection do
            background_check = BackgroundCheck.new({order_id: order_id, status: :pending})
            background_check.user = user
            background_check.save
          end
        end
      else
        ActiveRecord::Base.connection_pool.with_connection do
          background_check = BackgroundCheck.new({order_id: rand(100..99999), status: :ready})
          background_check.user = user
          background_check.save
        end
      end
    rescue Exception => e
      Rails.logger.error "Background check submission error: #{e}"
    end
  end
end
