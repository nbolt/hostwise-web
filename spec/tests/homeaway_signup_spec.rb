require_relative '../spec_helper'
require 'selenium-webdriver'
require 'rspec/expectations'
require 'headless'

def setup
  @headless = Headless.new
  @headless.start
  @driver = Selenium::WebDriver.for :firefox
end

def teardown
  @driver.quit
  @headless.destroy
end

def run
  setup
  yield
  teardown
end

def send_report(type, report)
  include ActionView::Helpers::TextHelper
  UserMailer.report("HomeAway #{type}", simple_format(report.join('<br>')), 'andre@hostwise.com').then(:deliver)
end

def logout
  @driver.execute_script("document.getElementById('signout').click();")
  sleep 5
end

def source
  1
end

run do
  report = []
  account_limit = 2
  base_email = 'jeannchen11'
  report << "creating #{account_limit} accounts..."

  account_limit.times do
    first_name = ['michelle', 'michal', 'donna', 'jeann', 'carol'].sample
    last_name = ['wong', 'lee', 'chin', 'chan', 'li'].sample

    email = "#{base_email}+#{Random.new.rand(1...10000)}@gmail.com"
    while BotAccount.where(email: email, source_cd: source).present?
      email = "#{base_email}+#{Random.new.rand(1...10000)}@gmail.com"
    end
    pwd = 'airbnb338'

    @driver.navigate.to 'https://cas.homeaway.com/auth/traveler/register?service=https%3A%2F%2Fwww.homeaway.com%2Fuser%2Fsso%2Fauth%3Flt%3Dtraveler%26context%3Ddef%26service%3D%252F&requestingBrand=homea'
    sleep 3

    login_form = @driver.find_element(:xpath, '//form[@id="login-form"]')
    login_form.find_element(:xpath, '//input[@id="firstName"]').send_keys first_name
    login_form.find_element(:xpath, '//input[@id="lastName"]').send_keys last_name
    login_form.find_element(:xpath, '//input[@id="emailAddress"]').send_keys email
    login_form.find_element(:xpath, '//input[@id="password"]').send_keys pwd
    login_form.find_element(:xpath, '//input[@id="form-submit"]').click
    sleep 3

    @driver.find_element(:xpath, '//a[contains(., "Continue")]').click

    begin
      acct = BotAccount.new({'email' => email,
                             'password' => pwd,
                             'status' => :active,
                             'source_cd' => source,
                             'last_run' => Date.yesterday})
      acct.save
      puts "HomeAway account created: #{email}"
      report << "HomeAway account created: #{email}"
      sleep 3
      logout
    rescue Exception => e
      report << e
    end
  end

  send_report 'signup', report
end
