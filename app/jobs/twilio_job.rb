class TwilioJob < ActiveJob::Base
  queue_as :default

  def perform(to, body, photos = nil)
    twilio = Twilio::REST::Client.new(ENV['TWILIO_SID'], ENV['TWILIO_TOKEN'])
    params = {from: '+14244445446', to: to, body: body}
    params[:media_url] = photos if photos.present?

    begin
      twilio.account.messages.create params
    rescue Exception => e
      Rails.logger.error "Twilio error: #{e}"
    end
  end
end
