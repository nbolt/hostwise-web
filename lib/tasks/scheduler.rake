namespace :booking do
  task send_reminder: :environment do
    bookings = Booking.tomorrow
    puts "Sending #{bookings.count} reminders..."
    bookings.each { |booking| booking.send_reminder }
    puts 'Reminders sent successfully.'
  end
end
