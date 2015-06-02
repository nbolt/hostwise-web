require 'spec_helper'
require 'selenium-webdriver'

describe 'homeaway' do
  include ActionView::Helpers::TextHelper

  def send_report(type, report)
    UserMailer.report("homeaway #{type}", simple_format(report.join('<br>')), 'andre@hostwise.com').then(:deliver)
  end

  def logout(driver)
    driver.find_element(:xpath, '//li[@id="user-dropdown"]//a[@id="user-drop"]').click
    sleep 3
    driver.find_element(:xpath, '//a[@id="signout"]').click
    sleep 5
  end

  it 'create account', type: 'signup' do
    report = []
    server = BrowserMob::Proxy::Server.new ENV['BROWSERMOB']
    server.start
    proxy = Selenium::WebDriver::Proxy.new(http: server.create_proxy.selenium_proxy.http)
    caps = Selenium::WebDriver::Remote::Capabilities.chrome(proxy: proxy)
    driver = Selenium::WebDriver.for(:chrome, desired_capabilities: caps)
    site = 'https://www.homeaway.com'

    account_limit = ENV['account_limit'].to_i
    report << "creating #{account_limit} accounts..."

    account_limit.times do
      first_name = ['michelle', 'michal', 'donna', 'jeann', 'carol'].sample
      last_name = ['wong', 'lee', 'chin', 'chan', 'li'].sample

      email = "#{ENV['base_email']}+#{Random.new.rand(1...10000)}@gmail.com"
      while BotAccount.where(email: email, source_cd: 1).present?
        email = "#{ENV['base_email']}+#{Random.new.rand(1...10000)}@gmail.com"
      end
      pwd = 'airbnb338'

      driver.navigate.to site
      driver.find_element(:xpath, '//ul[@class="nav"]//a[@class="traveler-sign-in"]').click
      sleep 3
      driver.find_element(:xpath, '//a[contains(., "Sign Up")]').click
      sleep 3

      login_form = driver.find_element(:xpath, '//form[@id="login-form"]')
      login_form.find_element(:xpath, '//input[@id="firstName"]').send_keys first_name
      login_form.find_element(:xpath, '//input[@id="lastName"]').send_keys last_name
      login_form.find_element(:xpath, '//input[@id="emailAddress"]').send_keys email
      login_form.find_element(:xpath, '//input[@id="password"]').send_keys pwd
      login_form.find_element(:xpath, '//input[@id="form-submit"]').click
      sleep 3

      driver.find_element(:xpath, '//a[contains(., "Continue")]').click

      begin
        acct = BotAccount.new({'email' => email,
                               'password' => pwd,
                               'status' => :active,
                               'source' => :homeaway,
                               'last_run' => Date.yesterday})
        acct.save
        report << "homeaway account created: #{email}"
        sleep 5
        logout driver
      rescue Exception => e
        report << e
      end
    end

    driver.quit
    server.stop
    send_report 'signup', report
  end

  it 'scrape properties', type: 'scrape' do
    report = []
    server = BrowserMob::Proxy::Server.new ENV['BROWSERMOB']
    server.start
    proxy = Selenium::WebDriver::Proxy.new(http: server.create_proxy.selenium_proxy.http)
    caps = Selenium::WebDriver::Remote::Capabilities.chrome(proxy: proxy)
    driver = Selenium::WebDriver.for(:chrome, desired_capabilities: caps)
    site = 'https://www.homeaway.com'

    location = URI.unescape ENV['location']
    report << "scraping properties at #{location}..."

    driver.navigate.to site
    search_form = driver.find_element(:xpath, '//form[@name="searchForm"]')
    search_form.find_element(:xpath, '//input[@id="searchKeywords"]').send_keys location
    search_form.find_element(:xpath, '//button[@type="button"]').click
    sleep 5

    #loop through each result
    base_url = driver.current_url
    per_page = 30
    total = driver.find_element(:xpath, '//div[@class="pager pager-right pager-gt-search"]//li[@class="page"]').text.split('of').last.strip.remove(',').to_i
    last_page = (total.to_f / per_page.to_f).ceil.to_i
    puts "#{base_url}, #{per_page}, #{total}, #{last_page}"
    (29..last_page).each do |i|
      driver.navigate.to "#{base_url}/page:#{i}"
      sleep 1

      collection = driver.find_element(:xpath, '//div[@class="js-listHitCollectionView preview-container"]')
      listings = collection.find_elements(:xpath, '//h3[@class="listing-title"]//a[@class="listing-url"]')
      report << "page: #{i} -> listings: #{listings.size}"

      result_hash = {}
      listings.each do |listing|
        property_url = listing.attribute('href')
        property_id = property_url.split('/').last.remove('p')
        property_name = listing.text
        result_hash[property_id] = {property_name: property_name,
                                    property_url: property_url}
      end

      result_hash.each do |key, value|
        #skip if already been scraped
        next if Bot.where(source_cd: 1, property_id: key).present?

        begin
          driver.get value[:property_url]
          sleep 1

          user_name = driver.find_element(:xpath, '//div[@class="about-the-owner"]//span[@class="owner-name"]').text rescue nil
          property_type = ''
          num_bedrooms = 0
          num_bathrooms = 0
          table = driver.find_elements(:xpath, '//table[@class="table table-striped amenity-table"]').first
          rows = table.find_elements(:xpath, '//tbody//tr')
          rows.each do |row|
            if row.text.include?('Property type') || row.text.include?('Bedrooms') || row.text.include?('Bathrooms')
              if row.text.include? 'Property type'
                property_type = row.text.split(' ').last.downcase
              elsif row.text.include? 'Bedrooms'
                num_bedrooms = row.text.split(' ').last == 'Studio' ? 0 : row.text.split(' ').last.to_i
              elsif row.text.include? 'Bathrooms'
                num_bathrooms = row.text.split(' ').last.to_i
              end
            end
          end

          #store all scraped data
          report << "name: #{user_name}, property id: #{key}, property name: #{value[:property_name]}, property url: #{value[:property_url]}, property type: #{property_type}, bedrooms: #{num_bedrooms}, bathrooms: #{num_bathrooms}"
          bot = Bot.new({'host_name' => user_name,
                         'property_id' => key,
                         'property_name' => value[:property_name],
                         'property_url' => value[:property_url],
                         'property_type' => property_type,
                         'num_bedrooms' => num_bedrooms,
                         'num_bathrooms' => num_bathrooms,
                         'status' => :active,
                         'source' => :homeaway,
                         'super_host' => false})
          bot.save
        rescue Exception => e
          report << "HomeAway error for #{key} #{value}: #{e}"
        end
      end
    end

    driver.quit
    server.stop
    send_report 'scrape', report
  end

  it 'make inquiry', type: 'booking' do
    report = []
    test = ENV['test'] == 'true'
    use_proxy = ENV['proxy'] == 'true'

    driver = Selenium::WebDriver.for :chrome
    if use_proxy
      server = BrowserMob::Proxy::Server.new ENV['BROWSERMOB']
      server.start
      proxy = Selenium::WebDriver::Proxy.new(http: server.create_proxy.selenium_proxy.http)
      caps = Selenium::WebDriver::Remote::Capabilities.chrome(proxy: proxy)
      driver = Selenium::WebDriver.for(:chrome, desired_capabilities: caps)
    end
    site = 'https://www.homeaway.com'

    message_limit = ENV['message_limit'].to_i
    account_limit = ENV['account_limit'].to_i
    messages = ["Hey |name|!\n\nI love your vacation rental. You should check out HostWise.com, (first clean free) I use them and if I refer a free service then I get another free service! :) You can do the same!",
                "Hey |name|!\n\nLooks like your vacation rental would be a perfect fit for our company, HostWise.com. Our company was created by hosts, for hosts. We automate the entire home turnover for you and guarantee a 5 star clean rating every time. Give us a try for first time for free, no strings attached. Not sure if you have many more properties, but if so we do offer enterprise pricing discounts as well! :)",
                "Hey |name|!\n\nI just started using HostWise.com to clean and turnover my property and think your property would be a perfect fit for them too. First service is free, no strings attached, I just got a coupon code for 10% off 3 services if your are interested I can give it to you!\n\nCheers!",
                "Hi |name|,\n\nDo you use HostWise.com for housekeeping, linens, towels?"]

    accounts = BotAccount.where('status_cd = 1 and source_cd = 1 and last_run < ?', Date.today).limit(account_limit)
    report << "accounts: #{accounts.count}"
    accounts.each do |account|
      username = account.email
      password = account.password
      driver.navigate.to site

      driver.find_element(:xpath, '//ul[@class="nav"]//a[@class="traveler-sign-in"]').click
      sleep 3

      login_form = driver.find_element(:xpath, '//form[@id="login-form"]')
      login_form.find_element(:xpath, '//input[@id="username"]').send_keys username
      login_form.find_element(:xpath, '//input[@id="password"]').send_keys password
      login_form.submit
      sleep 3

      total_message = 0
      records = Bot.where(source_cd: 1, status_cd: 1)
      report << "records: #{records.count}"
      records.each do |record|
        break if total_message >= message_limit  #STOP when limit reaches
        next if Bot.where(source_cd: 1, host_name: record.host_name, status_cd: 2).present? #SKIP when same host already been messaged

        begin
          driver.get record.property_url
          sleep 5
          contact_btn = driver.find_element(:xpath, '//a[@class="btn-inquiry-link cta btn btn-inquiry js-emailOwnerButton btn-link"]') rescue nil
          if contact_btn.present?
            contact_btn.click
          else
            driver.find_element(:xpath, '//a[@class="btn-inquiry-button cta btn btn-inquiry js-emailOwnerButton btn-primary cta-primary"]').click
          end
          sleep 3

          booking_form = driver.find_element(:xpath, '//form[@id="propertyInquiryForm"]')
          flex_date_cb = booking_form.find_element(:xpath, '//input[@name="flexibleInquiryDates"]')
          flex_date_cb.click unless flex_date_cb.selected?
          input_num_adults = booking_form.find_element(:xpath, '//input[@name="numberOfAdults"]')
          input_num_adults.clear
          input_num_adults.send_keys '2'
          message = messages[3].gsub '|name|', record.host_name ||= 'host'
          textarea = booking_form.find_element(:xpath, '//textarea[@name="comments"]')
          textarea.clear
          textarea.send_keys message
          sleep 3
          booking_form.submit unless test
          total_message += 1
          sleep 5
          report << "contacted host #{record.host_name} for property #{record.property_name}"
          unless test
            record.status = :contacted
            record.save
          end
        rescue Exception => e
          report << "HomeAway error for #{record.id}: #{e}"
        end
      end

      if total_message > 0
        account.last_run = Date.today
        account.save
      end

      driver.get site
      sleep 2
      logout driver
    end

    driver.quit
    server.stop if use_proxy
    send_report 'booking', report
  end
end
