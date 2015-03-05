namespace :launch do
  task new_users: :environment do
    # users = User.all
    users = User.where(email: 'andre@hostwise.com')
    puts "Resetting #{users.count} users..."
    users.each do |user|
      user.generate_reset_password_token!
      UserMailer.new_hostwise_email(user, "#{edit_password_reset_url(user.reset_password_token)}").then(:deliver)
    end
    puts 'Reset emails sent successfully.'
  end
end
