namespace :email_campaign do
  task sm_rally_annoucement: :environment do
    users = User.where(activation_state: 'active', email: 'andre@hostwise.com')
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
end
