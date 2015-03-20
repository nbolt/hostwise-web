ENV["RAILS_ENV"] = "test"

require 'simplecov'
SimpleCov.start

require File.expand_path("../../config/environment", __FILE__)
require "rails/test_help"
require "minitest/rails"
require "minitest/spec"

# To add Capybara feature tests add `gem "minitest-rails-capybara"`
# to the test group in the Gemfile and uncomment the following:
# require "minitest/rails/capybara"

# Uncomment for awesome colorful output
# require "minitest/pride"

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  class << self
    remove_method :describe
  end

  extend MiniTest::Spec::DSL

  register_spec_type self do |desc|
    desc < ActiveRecord::Base if desc.is_a? Class
  end

  # after { FileUtils.rm_rf(Dir["#{Rails.root}/test/support/uploads"]) }
end
