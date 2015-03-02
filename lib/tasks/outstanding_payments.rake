namespace :payments do
  task process_outstanding: :environment do
    Booking.where(payment_status_cd: 0, status_cd: 3).each do |booking|
      case booking.last_transaction.status_cd
      when 1
        booking.charge!
      when 2
        # check if bank debit succeeded 
      end
    end
  end
end
