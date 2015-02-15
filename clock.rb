require 'clockwork'

require './config/boot'
require './config/environment'

module Clockwork
  handler do |job|
    case job
    when 'payments.process'
      Booking.where(payment_status_cd: 0).each do |booking|
        case last_transaction.status_cd
        when 1
          booking.charge!
        when 2
          # check if bank debit succeeded
        end
      end
    when 'jobs.outstanding.process'
      Job.where(status_cd: [0,1,2]).where('bookings.date < ?', Date.today).includes(:booking).references(:booking).each do |job|
        job.past_due!
        job.save
      end
    end
  end

  every(1.day, 'payments.process', :at => '00:00')
  every(1.day, 'jobs.outstanding.process', :at => '00:00')
end