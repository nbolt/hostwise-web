namespace :booking do
  task send_reminder: :environment do
    bookings = Booking.tomorrow.where(status_cd: [1,4])
    puts "Sending #{bookings.count} reminders..."
    bookings.each do |booking|
      puts "Booking ID: #{booking.id}"
      booking.send_reminder
    end
    puts 'Reminders sent successfully.'
  end
end
