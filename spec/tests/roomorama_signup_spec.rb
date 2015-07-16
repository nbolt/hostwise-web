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
  UserMailer.report("roomorama #{type}", simple_format(report.join('<br>')), 'andre@hostwise.com').then(:deliver)
end

def logout
  @driver.find_element(:xpath, '//li[@class="user dropdown dropit-trigger"]//a').click
  sleep 3
  @driver.find_element(:xpath, '//div[@class="user-menu menu hide dropit-submenu"]//a[contains(., "Log Out")]').click
  sleep 5
end

def login(username, password)
  @driver.find_element(:xpath, '//a[@id="header-sign-in-link"]').click
  sleep 3

  login_form = @driver.find_element(:xpath, '//form[@id="new_session"]')
  login_form.find_element(:xpath, '//input[@id="session_login"]').send_keys username
  login_form.find_element(:xpath, '//input[@id="session_password"]').send_keys password
  login_form.submit
  sleep 3
end

def source
  2
end

run do
  report = []
  site = 'https://www.roomorama.com'
  account_limit = 5
  base_email = 'jeannchen11'
  report << "creating #{account_limit} accounts..."

  account_limit.times do
    first_name = ['michelle', 'michal', 'donna', 'jeann', 'carol'].sample
    last_name = ['wong', 'lee', 'chin', 'chan', 'li'].sample

    email = "#{base_email}+#{Random.new.rand(1...10000)}@gmail.com"
    while BotAccount.where(email: email, source_cd: 2).present?
      email = "#{base_email}+#{Random.new.rand(1...10000)}@gmail.com"
    end
    pwd = 'airbnb338'

    @driver.navigate.to site
    @driver.find_element(:xpath, '//a[@id="header-sign-up-link"]').click
    sleep 3
    @driver.find_element(:xpath, '//a[@id="signup-email"]').click
    sleep 3

    signup_form = @driver.find_element(:xpath, '//form[@id="new_user"]')
    signup_form.find_element(:xpath, '//input[@id="user_login"]').send_keys email.gsub('@gmail.com', '').gsub('+', '_')
    signup_form.find_element(:xpath, '//input[@id="user_first_name"]').send_keys first_name
    signup_form.find_element(:xpath, '//input[@id="user_last_name"]').send_keys last_name
    signup_form.find_element(:xpath, '//input[@id="user_email"]').send_keys email
    signup_form.find_element(:xpath, '//input[@id="user_password"]').send_keys pwd
    signup_form.find_element(:xpath, '//input[@id="user_phone_number"]').send_keys '6503239599'
    signup_form.submit
    sleep 3

    begin
      acct = BotAccount.new({'email' => email,
                             'password' => pwd,
                             'status' => :active,
                             'source_cd' => source,
                             'last_run' => Date.yesterday})
      acct.save
      puts "roomorama account created: #{email}"
      report << "roomorama account created: #{email}"
      sleep 5
      logout
    rescue Exception => e
      report << e
    end
  end

  send_report 'signup', report
end
