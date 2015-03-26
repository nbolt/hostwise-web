require 'json'

class BackgroundCheckSubmissionJob < ActiveJob::Base
  queue_as :default

  def perform(user)
    dob = user.contractor_profile.dob
    formatted_dob = [dob[4..dob.length-1], dob[0..1], dob[2..3]].join '-'
    ssn = "#{user.contractor_profile.ssn[0..2]}-#{user.contractor_profile.ssn[3..4]}-#{user.contractor_profile.ssn[5..8]}"
    application = {first_name: user.first_name,
                   last_name: user.last_name,
                   email: user.email,
                   phone: user.phone_number,
                   zipcode: user.contractor_profile.zip,
                   dob: formatted_dob,
                   ssn: Rails.env.production? ? ssn : '111-11-2001',
                   custom_id: user.id}

    begin
      candidate_res = RestClient.post "#{ENV['CHECKR_URL']}/v1/candidates", application.to_json, content_type: :json, accept: :json
      if candidate_res.code == 201
        candidate = JSON.parse candidate_res.body
        report_res = RestClient.post "#{ENV['CHECKR_URL']}/v1/reports", {package: 'tasker_basic', candidate_id: candidate['id']}.to_json, content_type: :json, accept: :json
        if report_res.code == 201
          report = JSON.parse report_res.body
          ActiveRecord::Base.connection_pool.with_connection do
            background_check = BackgroundCheck.new({order_id: report['id'] , status: Rails.env.production? && report['status'].to_sym || :clear})
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
