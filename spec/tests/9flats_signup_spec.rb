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
  UserMailer.report("9flats #{type}", simple_format(report.join('<br>')), 'andre@hostwise.com').then(:deliver)
end

def logout
  @driver.navigate.to 'https://www.9flats.com/users/sign_out'
  sleep 5
end

def login(username, password)
  @driver.navigate.to 'https://www.9flats.com/users/sign_in'
  sleep 3

  login_form = @driver.find_element(:xpath, '//form[@id="session_new"]')
  login_form.find_element(:xpath, '//input[@id="user_email"]').send_keys username
  login_form.find_element(:xpath, '//input[@id="user_password"]').send_keys password
  login_form.submit
  sleep 3
end

def source
  3
end

run do
  report = []
  site = 'https://www.9flats.com'
  #account_limit = ARGV[0].to_i
  #base_email = ARGV[1]
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

    @driver.navigate.to "#{site}/users/sign_in?signup=1"
    sleep 3

    signup_form = @driver.find_element(:xpath, '//form[@id="new_user"]')
    signup_form.find_element(:xpath, '//input[@id="user_first_name"]').send_keys first_name
    signup_form.find_element(:xpath, '//input[@id="user_last_name"]').send_keys last_name
    @driver.execute_script("document.getElementsByName('user[email]')[1].value='" + email + "'")
    @driver.execute_script("document.getElementsByName('user[password]')[1].value='airbnb338'")
    @driver.execute_script("document.getElementsByName('user[password_confirmation]')[0].value='airbnb338'")
    signup_form.submit
    sleep 3

    begin
      acct = BotAccount.new({'email' => email,
                             'password' => pwd,
                             'status' => :active,
                             'source_cd' => source,
                             'last_run' => Date.yesterday})
      acct.save
      puts "9flats account created: #{email}"
      report << "9flats account created: #{email}"
      sleep 3
      logout
    rescue Exception => e
      report << e
    end
  end

  send_report 'signup', report
end
