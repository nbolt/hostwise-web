require 'clockwork'

require './config/boot'
require './config/environment'

module Clockwork
  handler do |job|
    case job
    when 'payments.process'
      Booking.where(payment_status_cd: 0).each { |booking| booking.charge! }
    end
  end

  every(1.day, 'payments.process', :at => '00:00')
end