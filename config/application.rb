require File.expand_path('../boot', __FILE__)

require 'rails/all'

# Require the gems listed in Gemfile, including any gems
# you've limited to :test, :development, or :production.
Bundler.require(:default, :assets, Rails.env)

module PorterWeb
  class Application < Rails::Application
    #Stylus.setup Sprockets, config.assets rescue nil
    Stylus.use('axis-css') if defined?(Stylus)
    config.generators do |g|
      g.test_framework :mini_test, :spec => true, :fixture => true
      g.integration_tool :mini_test
    end
  end
end
