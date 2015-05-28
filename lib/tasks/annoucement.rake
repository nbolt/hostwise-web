namespace :email_campaign do
  task sm_rally_annoucement: :environment do
    users = User.where(activation_state: 'active')
    puts "Sending #{users.count} email..."
    users.each do |user|
      UserMailer.announcement(user, 'santa-monica-rally').then(:deliver)
    end
    puts 'Email sent successfully.'
  end

  task sm_rally_reminder: :environment do
    users = User.where(activation_state: 'active')
    puts "Sending #{users.count} email..."
    users.each do |user|
      UserMailer.announcement(user, 'santa-monica-rally-reminder').then(:deliver)
    end
    puts 'Email sent successfully.'
  end

  task dynamic_schedule_launch: :environment do
    users = User.hosts.select {|user| user.bookings.present? && user.bookings.sort_by{|b| b.date}[-1].date >= Date.today - 2.months}
    puts "Sending #{users.count} email..."
    users.each do |user|
      UserMailer.announcement(user, 'dynamic-schedule-launch').then(:deliver)
    end
    puts 'Email sent successfully.'
  end

  task buy_rent_program_launch: :environment do
    users = User.hosts.select {|user| user.bookings.present? && user.bookings.sort_by{|b| b.date}[-1].date >= Date.today - 2.weeks}
    puts "Sending #{users.count} email..."
    users.each do |user|
      UserMailer.announcement(user, 'buy-vs-rent-program-launch').then(:deliver)
    end
    puts 'Email sent successfully.'
  end

  task first_service_free_reminder: :environment do
    users = User.where(role_cd: 1, activation_state: 'active')
    puts "Sending #{users.count} email..."
    users.each do |user|
      booking_count = user.properties.reduce(0) {|acc, property| acc + property.bookings.count}
      UserMailer.announcement(user, 'first-service-free-campaign').then(:deliver) unless booking_count > 0
    end
    puts 'Email sent successfully.'
  end

  task retention_promo: :environment do
    users = User.where(role_cd: 1, activation_state: 'active')
    puts "Sending #{users.count} email..."
    users.each do |user|
      booking_count = user.properties.reduce(0) {|acc, property| acc + property.bookings.count}
      UserMailer.announcement(user, 'retention-promo-campaign').then(:deliver) if booking_count > 0
    end
    puts 'Email sent successfully.'
  end
end
