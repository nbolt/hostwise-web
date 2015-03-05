namespace :migrate do
  task new_users: :environment do
    User.where(salt: '.').each do |user|
      user.create_stripe_customer
      user.create_balanced_customer
      user.generate_reset_password_token!
      UserMailer.reset_password_email(user, "https://www.hostwise.com/password_resets/#{user.reset_password_token}/edit").then(:deliver)
    end
  end
end
