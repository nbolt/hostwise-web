namespace :launch do
  task test: :environment do
    users = User.where({email: ['andre@hostwise.com', 'matthewlucido@gmail.com']})
    puts "Resetting #{users.count} users..."
    users.each do |user|
      user.generate_reset_password_token!
      if user.reset_password_token.present?
        UserMailer.launch_email(user, "https://www.hostwise.com/password_resets/#{user.reset_password_token}/edit").then(:deliver)
      end
    end
    puts 'Reset emails sent successfully.'
  end

  task new_users: :environment do
    users = User.all
    puts "Resetting #{users.count} users..."
    users.each do |user|
      if user.reset_password_token.present?
        UserMailer.launch_email(user, "https://www.hostwise.com/password_resets/#{user.reset_password_token}/edit").then(:deliver)
      end
    end
    puts 'Reset emails sent successfully.'
  end
end
