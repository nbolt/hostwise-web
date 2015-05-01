namespace :test do
  task e2e: :environment do
    ENV['RAILS_ENV'] = 'test'
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean
    system "protractor #{Rails.root.join('config', 'protractor.conf.js')} --baseUrl=http://localhost:3000"
  end
end
