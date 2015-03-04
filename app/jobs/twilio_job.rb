class TwilioJob < ActiveJob::Base
  queue_as :default

  def perform(to, body)
    twilio = Twilio::REST::Client.new(ENV['TWILIO_SID'], ENV['TWILIO_TOKEN'])
    begin
      twilio.account.messages.create(
        from: '+14244445446',
        to: to,
        body: body
      )
    rescue Exception => e
      Rails.logger.error "Twilio error: #{e}"
    end
  end
end
