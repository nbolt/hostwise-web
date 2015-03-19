require 'json'

class BackgroundCheckSubmissionJob < ActiveJob::Base
  queue_as :default

  def perform(user, application)
    begin
      candidate_res = RestClient.post "#{ENV['CHECKR_URL']}/v1/candidates", application.to_json, content_type: :json, accept: :json
      if candidate_res.code == 201
        candidate = JSON.parse candidate_res.body
        report_res = RestClient.post "#{ENV['CHECKR_URL']}/v1/reports", {package: 'tasker_basic', candidate_id: candidate['id']}.to_json, content_type: :json, accept: :json
        if report_res.code == 201
          report = JSON.parse report_res.body
          ActiveRecord::Base.connection_pool.with_connection do
            background_check = BackgroundCheck.new({order_id: report['id'] , status: report['status'].to_sym})
            background_check.user = user
            background_check.save
          end
        end
      end
    rescue Exception => e
      Rails.logger.error "Background check submission error: #{e}"
    end
  end
end
