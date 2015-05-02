namespace :test do
  task e2e: :environment do
    ENV['RAILS_ENV'] = 'test'
    DatabaseCleaner.strategy = :transaction
    DatabaseCleaner.clean
    sh "./node_modules/protractor/bin/protractor #{Rails.root.join('config', 'protractor.conf.js')}"
  end
end
