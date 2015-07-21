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
  UserMailer.report("roomorame #{type}", simple_format(report.join('<br>')), 'andre@hostwise.com').then(:deliver)
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
  start_page = 1
  month_limit = 5
  message_limit = 2
  account_limit = 2
  total_all_msg = 0
  test = false

  messages = ["Hey |name|!\n\nI love your vacation rental. You should check out HostWise.com, (first clean free) I use them and if I refer a free service then I get another free service! :) You can do the same!",
              "Hey |name|!\n\nLooks like your vacation rental would be a perfect fit for our company, HostWise.com. Our company was created by hosts, for hosts. We automate the entire home turnover for you and guarantee a 5 star clean rating every time. Give us a try for first time for free, no strings attached. Not sure if you have many more properties, but if so we do offer enterprise pricing discounts as well! :)",
              "Hey |name|!\n\nI just started using HostWise.com to clean and turnover my property and think your property would be a perfect fit for them too. First service is free, no strings attached, I just got a coupon code for 10% off 3 services if your are interested I can give it to you!\n\nCheers!",
              "Hi |name|!\n\nDo you use HostWise.com to clean and restock your property? The last rental we booked in LA did and the presentation was hotel caliber - from linens and towels to toiletries just for the guests. They're still doing FREE TRIALS at HostWise.com, by the way.\n\nCoupon code: TRYHOSTWISE100\n\nCheers!",
              "Hi |name|,\n\nDo you use HostWise.com for housekeeping, linens, towels?"]

  site = 'https://www.roomorama.com'
  location = URI.unescape 'Los Angeles, CA'
  puts "scraping properties at #{location}..."
  report << "scraping properties at #{location}..."

  accounts = BotAccount.where('status_cd = 1 and source_cd = ? and last_run < ?', source, Date.today).limit(account_limit)
  report << "accounts: #{accounts.count}"
  accounts.each do |account|
    username = account.email
    password = account.password
    puts "logging into account: #{username}"
    @driver.navigate.to site

    login username, password

    if @driver.current_url == "#{site}/login" #account disabled
      puts "deactivating account: #{username}"
      report << "deactivating account: #{username}"
      account.status = :deactivated
      account.save
      next
    end

    @driver.navigate.to site

    begin
      @driver.find_element(:xpath, '//input[@id="no_specify_dates"]').click
    rescue
    end
    search_form = @driver.find_element(:xpath, '//div[@class="search-form clearfix"]')
    search_form.find_element(:xpath, '//input[@name="q"]').send_keys location
    search_form.find_element(:xpath, '//button[@type="submit"]').click
    sleep 5

    #loop through each result
    @driver.find_element(:xpath, '//input[@id="room-type-apartment"]').click
    sleep 2
    @driver.find_element(:xpath, '//input[@id="room-type-house"]').click
    sleep 2
    @driver.find_element(:xpath, '//input[@id="room-type-room"]').click
    sleep 2

    base_url = @driver.current_url
    last_page = @driver.find_element(:xpath, '//nav[@class="pagination pagination-centered"]//ul//li[last()-1]//a').text.to_i
    total_message = 0
    puts "#{base_url}, #{start_page}, #{last_page}"
    (start_page..last_page).each do |i|
      current_page = base_url.split('&').last.split('=').last.to_i
      base_url = base_url.gsub("page=#{current_page}", "page=#{i}")
      @driver.navigate.to base_url
      sleep 1

      search_results = @driver.find_element(:xpath, '//div[@id="search-results"]')
      items = search_results.find_elements(:xpath, '//div[@class="details span5"]//h2[@class="room-title"]//a')
      puts "page: #{i} -> items: #{items.size}"
      report << "page: #{i} -> items: #{items.size}"

      result_hash = {}
      items.each do |item|
        next unless item.attribute('href').present?
        property_url = item.attribute('href').split('?').first
        property_id = property_url.split('/').last
        property_name = item.text
        result_hash[property_id] = {property_name: property_name,
                                    property_url: property_url}
      end

      result_hash.each do |key, value|
        record = Bot.where(source_cd: source, property_id: key)[0]
        puts "already scraped property id: #{key}" if record.present?

        break if total_message >= message_limit  #STOP when limit reaches

        #begin
          puts value[:property_url]
          @driver.get value[:property_url]
          sleep 1

          unless record.present?
            profile_url = @driver.find_element(:xpath, '//div[@class="host-header"]//a').attribute('href')
            user_id = profile_url.split('/').last
            address = @driver.find_element(:xpath, '//a[@class="property-location js-property-location"]//span[@class="room-destination"]').text.strip
            property_type = ''
            num_bedrooms = 0
            num_bathrooms = 0
            features = @driver.find_elements(:xpath, '//div[@class="property-details"]//p[@class="detail-line"]')
            features.each do |feature|
              parts = feature.text.split(' ')
              if parts.include?('Property') && parts.include?('Type')
                property_type = parts.last.downcase
              elsif parts.include?('Number') && parts.include?('Rooms')
                num_bedrooms = parts.last.to_i unless parts.last == 'Studio'
              elsif parts.include?('Number') && parts.include?('Bathrooms')
                num_bathrooms = parts.last.to_i
              end
            end

            #store all scraped data
            puts "user: #{user_id}, name: #{user_id}, property id: #{key}, property name: #{value[:property_name]}, property url: #{value[:property_url]}, profile url: #{profile_url}, address: #{address}, property type: #{property_type}, bedrooms: #{num_bedrooms}, bathrooms: #{num_bathrooms}"
            report << "user: #{user_id}, name: #{user_id}, property id: #{key}, property name: #{value[:property_name]}, property url: #{value[:property_url]}, profile url: #{profile_url}, address: #{address}, property type: #{property_type}, bedrooms: #{num_bedrooms}, bathrooms: #{num_bathrooms}"
            record = Bot.new({'host_name' => user_id,
                              'profile_id' => user_id,
                              'profile_url' => profile_url,
                              'property_id' => key,
                              'property_name' => value[:property_name],
                              'property_url' => value[:property_url],
                              'address' => address,
                              'property_type' => property_type,
                              'num_bedrooms' => num_bedrooms,
                              'num_bathrooms' => num_bathrooms,
                              'status' => :active,
                              'source_cd' => source,
                              'super_host' => false})
            record.save
          end

          if Bot.where('source_cd = ? and profile_id = ? and last_contacted > ?', source, record.profile_id, Date.today - 7.days).present? #SKIP when same host already been messaged recently
            puts "already messaged this host #{record.profile_id}"
            next
          end

          #book
          @driver.find_element(:xpath, '//div[@class="host-info-footer"]//a').click
          sleep 1
          contact_form = @driver.find_element(:xpath, '//form[@id="new-inquiry"]')

          default_guest = 1
          guest_ddl = Selenium::WebDriver::Support::Select.new(contact_form.find_element(:xpath, '//select[@id="contact_host_num_guests"]'))
          guest_ddl.options.reverse.each do |ele|
            default_guest = 2 if ele.text == '2' #pick 2 guests if available otherwise default to 1 guest
          end
          guest_ddl.select_by(:value, default_guest.to_s)
          sleep 2

          question_ddl = Selenium::WebDriver::Support::Select.new(contact_form.find_element(:xpath, '//select[@id="inquiry_reason_for_contact"]'))
          question_ddl.select_by(:value, 'other')
          sleep 2

          message = messages[3].gsub '|name|', record.host_name ||= 'host'
          textarea = contact_form.find_element(:xpath, '//textarea[@class="js-messaging-el"]')
          textarea.clear
          textarea.send_keys message
          sleep 3

          contact_form.find_element(:xpath, '//input[@id="contact_host_start_date"]').click
          sleep 1
          available_dates = nil
          date_selected_index = -1
          month_index = 0
          while !available_dates.present? && month_index < month_limit
            calendar = @driver.find_element(:xpath, '//div[@id="ui-datepicker-div"]')
            available_dates = calendar.find_elements(:xpath, '//table[@class="ui-datepicker-calendar"]//td[@data-handler="selectDay"]')
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
                calendar.find_element(:xpath, '//a[@class="ui-datepicker-next ui-corner-all"]').click
                available_dates = nil
                month_index += 1
                sleep 3
              end
            else #try next month
              calendar.find_element(:xpath, '//a[@class="ui-datepicker-next ui-corner-all"]').click
              available_dates = nil
              month_index += 1
              sleep 3
            end
          end

          if month_index >= month_limit #update invalid host
            record.status = :deleted
            record.save
          else
            unless test
              contact_form.find_element(:xpath, '//div[@class="btn-group message-actions"]//button').click
              sleep 1
              contact_form.find_element(:xpath, '//button[@class="btn btn-secondary btn-mini js-messaging-el js-send-message"]').click unless test
              sleep 3
              message_sent = contact_form.find_element(:xpath, '//div[@class="message-sent-text row-fluid"]') rescue nil
              if message_sent.present?
                total_message += 1
                total_all_msg += 1
                puts "contacted host #{record.host_name} for property #{record.property_name}"
                report << "contacted host #{record.host_name} for property #{record.property_name}"
                record.status = :contacted
                record.last_contacted = Date.today
                record.save
              end
            else
              total_message += 1
            end
          end
        # rescue Exception => e
        #   report << "Roomorama error for #{key} #{value}: #{e}"
        # end
      end

      if total_message >= message_limit  #STOP when limit reaches
        puts "next run starts at page:#{i}"
        report << "next run starts at page:#{i}"
        start_page = i
        break
      end
    end

    account.last_run = Date.today
    account.save
    puts "total sent: #{total_all_msg}"
    report << "total sent: #{total_all_msg}"

    @driver.navigate.to site
    sleep 2
    logout
  end

  send_report 'scrape', report
end
