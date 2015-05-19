namespace :test do
  task e2e: :environment do
    ENV['RAILS_ENV'] = 'test'
    ENV['e2e']       = true
    DatabaseCleaner.clean_with :truncation
    load Rails.root + "db/seeds.rb"
    sh "./node_modules/protractor/bin/protractor #{Rails.root.join('config', 'protractor.conf.js')}"
    DatabaseCleaner.clean_with :truncation
  end
end
