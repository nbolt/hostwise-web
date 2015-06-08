require 'spec_helper'
require 'selenium-webdriver'

describe 'airbnb' do
  include ActionView::Helpers::TextHelper

  def send_report(type, report)
    UserMailer.report("airbnb #{type}", simple_format(report.join('<br>')), 'andre@hostwise.com').then(:deliver)
  end

  def logout(driver)
    sleep 3
    driver.find_element(:xpath, '//a[@id="header-avatar-trigger"]').click
    sleep 3
    driver.find_element(:xpath, '//a[@class="no-crawl link-reset menu-item header-logout"]').click
    sleep 5
  end

  it 'create account', type: 'signup' do
    report = []
    server = BrowserMob::Proxy::Server.new ENV['BROWSERMOB']
    server.start
    proxy = Selenium::WebDriver::Proxy.new(http: server.create_proxy.selenium_proxy.http)
    caps = Selenium::WebDriver::Remote::Capabilities.chrome(proxy: proxy)
    driver = Selenium::WebDriver.for(:chrome, desired_capabilities: caps)
    site = 'https://www.airbnb.com'
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
      driver.find_element(:xpath, '//li[@id="sign_up"]//a').click
      sleep 3
      driver.find_element(:xpath, '//a[@class="create-using-email btn-block  row-space-2 btn btn-primary btn-block btn-large large icon-btn"]').click
      sleep 3
      login_form = driver.find_element(:xpath, '//form[@class="signup-form"]')
      login_form.find_element(:xpath, '//div[@id="inputFirst"]//input').send_keys first_name
      login_form.find_element(:xpath, '//div[@id="inputLast"]//input').send_keys last_name
      login_form.find_element(:xpath, '//div[@id="inputEmail"]//input').send_keys email
      login_form.find_element(:xpath, '//div[@id="inputPassword"]//input').send_keys pwd
      login_form.find_element(:xpath, '//div[@id="inputConfirmPassword"]//input').send_keys(pwd) rescue nil
      begin
        Selenium::WebDriver::Support::Select.new(login_form.find_element(:xpath, '//select[@id="user_birthday_month"]')).select_by(:value, '3')
        Selenium::WebDriver::Support::Select.new(login_form.find_element(:xpath, '//select[@id="user_birthday_day"]')).select_by(:value, '5')
        Selenium::WebDriver::Support::Select.new(login_form.find_element(:xpath, '//select[@id="user_birthday_year"]')).select_by(:value, '1978')
      rescue Exception => e
      end
      login_form.submit
      sleep 3

      begin
        #contact customer support warning
        alert = driver.find_element(:xpath, '//div[@id="signup-modal-content"]//div[@class="alert alert-with-icon alert-error alert-header panel-header hidden-element"]')
        if alert.displayed?
          report << "account #{email} requires further action: #{alert.text}"
          next
        end
      rescue Exception => e
      end

      driver.navigate.to site

      begin
        if driver.find_element(:xpath, '//div[@class="flash-container"]//div[contains(., "Account access is limited until you complete verification")]').displayed?
          report << "account #{email} requires further verification."
        end
        if driver.find_element(:xpath, '//div[@class="alert alert-with-icon alert-error alert-header panel-header hidden-element"]').displayed?
          report << 'process blocked: please try again later'
          break
        end
        driver.find_element(:xpath, '//div[@class="modal-content"]//div[@class="panel-footer"]//button[contains(., "Skip")]').click
      rescue Exception => e
      end

      acct = BotAccount.new({'email' => email,
                             'password' => pwd,
                             'status' => :active,
                             'source' => :airbnb,
                             'last_run' => Date.yesterday})
      acct.save
      report << "airbnb account created: #{email}"
      sleep 5

      logout driver
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
    site = 'https://www.airbnb.com'
    driver.navigate.to site

    #search
    location = ENV['location']
    report << "scraping properties at #{location}..."
    search_form = driver.find_element(:xpath, '//form[@id="search_form"]')
    search_form.find_element(:xpath, '//input[@id="location"]').send_keys location
    search_form.submit
    sleep 1

    #loop through each result
    base_url = driver.current_url.split('?').first
    last_page = driver.find_element(:xpath, '//div[@class="results-footer"]//ul//li[last()-1]//a')
    (1..last_page.text.to_i).each do |i|
      driver.navigate.to "#{base_url}?page=#{i}"
      sleep 1
      search_results = driver.find_element(:xpath, '//div[@class="search-results"]//div[@class="row listings-container"]')
      items = search_results.find_elements(:xpath, '//div[@class="listing"]')
      report << "page: #{i} -> items: #{items.size}"

      result_hash = {}
      items.each do |item|
        property_id = item.attribute('data-id')
        user_id = item.attribute('data-user')
        result_hash[property_id] = {user_id: user_id,
                                    profile_url: "#{site}/users/show/#{user_id}",
                                    property_name: item.attribute('data-name'),
                                    property_url: "#{site}#{item.attribute('data-url')}"}
      end

      result_hash.each do |key, value|
        #skip if already been scraped
        next if Bot.where(source_cd: 0, profile_id: value[:user_id], property_id: key).present?

        begin
          driver.get value[:property_url]
          sleep 1

          superhost = driver.find_element(:xpath, '//div[@id="superhost-badge-profile"]') rescue nil
          user_name = driver.find_element(:xpath, '//div[@id="host-profile"]//div[@class="row"]//div[@class="col-lg-8"]//h4').text.split(',').last.strip
          map = driver.find_elements(:xpath, '//div[@id="neighborhood"]//div[@class="panel location-panel"]//div[@class="panel"]//div[@class="panel-body"]').last
          address = map.find_elements(:xpath, '//div[@class="text-center"]').last.text
          feature_section = driver.find_elements(:xpath, '//div[@id="details"]//div[@id="details-column"]//div[@class="col-md-9"]').first
          features = feature_section.find_elements(:xpath, '//div[@class="col-md-6"]//div')

          property_type = ''
          num_bedrooms = 0
          num_bathrooms = 0
          num_beds = 0
          features.each do |feature|
            text = feature.text
            if text.include? 'Property type:'
              property_type = text.split(' ').last.downcase
            elsif text.include? 'Bedrooms:'
              num_bedrooms = text.split(' ').last.to_i
            elsif text.include? 'Bathrooms:'
              num_bathrooms = text.split(' ').last.to_i
            elsif text.include? 'Beds:'
              num_beds = text.split(' ').last.to_i
            end
          end

          #store all scraped data
          report << "user: #{value[:user_id]}, name: #{user_name}, property id: #{key}, property name: #{value[:property_name]}, property url: #{value[:property_url]}, profile url: #{value[:profile_url]}, superhost: #{superhost.present?}, address: #{address}, property type: #{property_type}, bedrooms: #{num_bedrooms}, bathrooms: #{num_bathrooms}, beds: #{num_beds}"
          bot = Bot.new({'host_name' => user_name,
                         'profile_id' => value[:user_id],
                         'profile_url' => value[:profile_url],
                         'property_id' => key,
                         'property_name' => value[:property_name],
                         'property_url' => value[:property_url],
                         'address' => address,
                         'property_type' => property_type,
                         'num_bedrooms' => num_bedrooms,
                         'num_bathrooms' => num_bathrooms,
                         'num_beds' => num_beds,
                         'status' => :active,
                         'source' => :airbnb,
                         'super_host' => superhost.present?})
          bot.save
        rescue Exception => e
          report << "AirBnb error for #{key} #{value}: #{e}"
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
    site = 'https://www.airbnb.com'

    month_limit = 5
    message_limit = ENV['message_limit'].to_i
    account_limit = ENV['account_limit'].to_i
    messages = ["Hey |name|!\n\nI love your vacation rental. You should check out HostWise[.com], (first clean free) I use them and if I refer a free service then I get another free service! :) You can do the same!",
                "Hey |name|!\n\nLooks like your vacation rental would be a perfect fit for our company, HostWise[.com]. Our company was created by hosts, for hosts. We automate the entire home turnover for you and guarantee a 5 star clean rating every time. Give us a try for first time for free, no strings attached. Not sure if you have many more properties, but if so we do offer enterprise pricing discounts as well! :)",
                "Hey |name|!\n\nI just started using HostWise[.com] to clean and turnover my property and think your property would be a perfect fit for them too. First service is free, no strings attached, I just got a coupon code for 10% off 3 services if your are interested I can give it to you!\n\nCheers!",
                "Hey |name|!\n\nI just started using HostWise[.com] and they are giving me 5 star cleaning ratings across the board. Figured I would pass it on to spread the word as much as possible! :) It's super easy to set up your property, took me less than 5 mins, Cheers!"]

    accounts = BotAccount.where('status_cd = 1 and source_cd = 0 and last_run < ?', Date.today).limit(account_limit)
    report << "accounts: #{accounts.count}"
    accounts.each do |account|
      username = account.email
      password = account.password
      driver.navigate.to site

      driver.find_element(:xpath, '//li[@id="login"]//a').click
      sleep 3

      report << "logging into account: #{username}"
      login_form = driver.find_element(:xpath, '//form[@class="signin-form login-form"]')
      login_form.find_element(:xpath, '//input[@id="signin_email"]').send_keys username
      login_form.find_element(:xpath, '//input[@id="signin_password"]').send_keys password
      login_form.submit
      sleep 1

      begin
        #update account status if account has been disabled
        if driver.find_element(:xpath, '//div[@id="account_recovery_panel"]').displayed?
          if driver.find_element(:xpath, 'h3[@class="text-special"]').text == 'Account Disabled'
            account.status = :deactivated
            account.save
            driver.navigate.to site
            logout driver
            next
          end
        end
        #update account status if account required further verification
        driver.get "#{site}/account"
        sleep 3
        verify_id = driver.find_element(:xpath, '//div[@class="vid-intro text-copy"]//h2') rescue nil
        if verify_id.present?
          puts verify_id.text
          if verify_id.text == 'We need to do a virtual ID check'
            report << "account #{email} requires further verification."
            account.status = :pending
            account.save
            driver.navigate.to site
            logout driver
            next
          end
        end
      rescue Exception => e
      end

      #loop through each result
      total_message = 0
      records = Bot.where(source_cd: 0, status_cd: 1, super_host: ENV['super_host'] == 'true').to_a
      records.keep_if { |record| Bot.where(status_cd: 2, profile_id: record.profile_id).count == 0 }
      report << "records: #{records.count}"
      records.each do |record|
        break if total_message >= message_limit  #STOP when limit reaches
        next if Bot.where(source_cd: 0, profile_id: record.profile_id, status_cd: 2).present? #SKIP when same host already been messaged

        begin
          puts record.property_url
          driver.get record.property_url
          sleep 1

          #click contact host button
          driver.find_element(:xpath, '//button[@id="host-profile-contact-btn"]').click
          sleep 3
          contact_form = driver.find_element(:xpath, '//form[@id="message_form"]')

          #set message
          message = messages[2].gsub '|name|', record.host_name ||= 'host'
          textarea = contact_form.find_element(:xpath, '//textarea[@id="question"]')
          textarea.clear
          textarea.send_keys message
          sleep 3

          #set guest - some properties will have only 1 guest option
          default_guest = 1
          guest_ddl = Selenium::WebDriver::Support::Select.new(contact_form.find_element(:xpath, '//select[@id="message_number_of_guests"]'))
          guest_ddl.options.reverse.each do |ele|
            default_guest = 2 if ele.text.split(' ').first == '2' #pick 2 guests if available otherwise default to 1 guest
          end
          guest_ddl.select_by(:value, default_guest.to_s)
          sleep 1

          #pick checkin date
          contact_form.find_element(:xpath, '//input[@id="message_checkin"]').click
          sleep 5
          available_dates = nil
          date_selected_index = -1
          month_index = 0
          while !available_dates.present? && month_index < month_limit
            calendar = contact_form.find_element(:xpath, '//div[@class="ui-datepicker ui-widget ui-widget-content ui-helper-clearfix ui-corner-all"]')
            available_dates = calendar.find_elements(:xpath, '//table[@class="ui-datepicker-calendar"]//tbody//a[@class="ui-state-default"]') rescue nil
            if available_dates.present?
              dates = available_dates.collect {|date| date.text.to_i}
              dates.each_with_index do |date, index|
                if dates.include? (dates[index] + 1)
                  date_selected_index = index
                  break
                end
              end
              if date_selected_index > -1
                available_dates[date_selected_index].click
                sleep 3
                break
              else #try next month
                calendar.find_element(:xpath, '//a[@class="ui-datepicker-next icon icon-chevron-right ui-corner-all"]').click
                available_dates = nil
                month_index += 1
                sleep 3
              end
            else #try next month
              calendar.find_element(:xpath, '//a[@class="ui-datepicker-next icon icon-chevron-right ui-corner-all"]').click
              available_dates = nil
              month_index += 1
              sleep 3
            end
          end

          if month_index >= month_limit #update invalid host
            record.status = :deleted
            record.save
          end

          error_box = contact_form.find_element(:xpath, '//div[@id="messaging-errors"]')
          if error_box.displayed? && !error_box.text.include?("You've contacted this host before")
            report << "failed booking #{record.id} #{record.host_name} at property #{record.property_name}"
          else
            contact_form.submit unless test
            total_message += 1
            sleep 5
            report << "contacted host #{record.host_name} for property #{record.property_name}"
            unless test
              record.status = :contacted
              record.save
            end
          end
        rescue Exception => e
          puts e
          report << "AirBnb error for #{record.id}: #{e}"
        end
      end

      if total_message > 0
        account.last_run = Date.today
        account.save
      end

      driver.navigate.to site
      logout driver
    end

    driver.quit
    server.stop if use_proxy
    send_report 'booking', report
  end
end
