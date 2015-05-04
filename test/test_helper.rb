ENV["RAILS_ENV"] = "test"

include Sorcery::TestHelpers::Rails::Controller
require 'simplecov'
SimpleCov.start

require File.expand_path("../../config/environment", __FILE__)
require "rails/test_help"
require "minitest/rails"
require "minitest/spec"
require 'minitest/profile'
require 'stripe'

DatabaseCleaner.strategy = :transaction
DatabaseCleaner.start
load Rails.root + "db/seeds.rb"

# To add Capybara feature tests add `gem "minitest-rails-capybara"`
# to the test group in the Gemfile and uncomment the following:
# require "minitest/rails/capybara"

# Uncomment for awesome colorful output
# require "minitest/pride"

module Stripe
  module CertificateBlacklist
    def self.check_ssl_cert(uri, ca_file)
      true
    end
  end
end

class Minitest::Spec
  around do |tests|
    DatabaseCleaner.cleaning(&tests)
  end
end

class ActiveSupport::TestCase
  ActiveRecord::Migration.check_pending!
  include FactoryGirl::Syntax::Methods

  # Setup all fixtures in test/fixtures/*.(yml|csv) for all tests in alphabetical order.
  #
  # Note: You'll currently still have to declare fixtures explicitly in integration tests
  # -- they do not yet inherit this setting
  fixtures :all

  # Add more helper methods to be used by all tests here...

  #class << self
  #  remove_method :describe
  #end

  extend MiniTest::Spec::DSL

  register_spec_type self do |desc|
    desc < ActiveRecord::Base if desc.is_a? Class
  end

  # after { FileUtils.rm_rf(Dir["#{Rails.root}/test/support/uploads"]) }
end
