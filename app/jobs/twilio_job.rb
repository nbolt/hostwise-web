class TwilioJob
  include SuckerPunch::Job

  def perform(to, body)
    twilio = Twilio::REST::Client.new(ENV['TWILIO_SID'], ENV['TWILIO_TOKEN'])
    twilio.account.messages.create(
      from: '+16108136144',
      to: to,
      body: body
    )
  end
end