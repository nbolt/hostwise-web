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
  start_page = 1
  message_limit = 2
  account_limit = 5
  total_all_msg = 0

  messages = ["Hey |name|!\n\nI love your vacation rental. You should check out HostWise.com, (first clean free) I use them and if I refer a free service then I get another free service! :) You can do the same!",
              "Hey |name|!\n\nLooks like your vacation rental would be a perfect fit for our company, HostWise.com. Our company was created by hosts, for hosts. We automate the entire home turnover for you and guarantee a 5 star clean rating every time. Give us a try for first time for free, no strings attached. Not sure if you have many more properties, but if so we do offer enterprise pricing discounts as well! :)",
              "Hey |name|!\n\nI just started using HostWise.com to clean and turnover my property and think your property would be a perfect fit for them too. First service is free, no strings attached, I just got a coupon code for 10% off 3 services if your are interested I can give it to you!\n\nCheers!",
              "Hi |name|!\n\nDo you use HostWise.com to clean and restock your property? The last rental we booked in LA did and the presentation was hotel caliber - from linens and towels to toiletries just for the guests. They're still doing FREE TRIALS at HostWise.com, by the way.\n\nCoupon code: TRYHOSTWISE100\n\nCheers!",
              "Hi |name|,\n\nDo you use HostWise.com for housekeeping, linens, towels?"]

  site = 'https://www.9flats.com'

  location = URI.unescape 'Los Angeles, United States'
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

    search_form = @driver.find_element(:xpath, '//form[@id="search_form"]')
    search_form.find_element(:xpath, '//input[@name="search[query]"]').send_keys location
    search_form.find_element(:xpath, '//input[@name="search[start_date]"]').click
    search_form.submit
    sleep 5

    base_url = @driver.current_url
    pagination = @driver.find_element(:xpath, '//span[@class="search__pagination__info"]').text
    last_page = (pagination.split(' ')[2].to_i / pagination.split(' ')[0].split('-').last.to_f).ceil
    total_message = 0
    puts "#{base_url}, #{start_page}, #{last_page}"
    (start_page..last_page).each do |i|
      if i > 1
        @driver.navigate.to base_url
        sleep 3

        if i > 5 #need to click page 5 to expand the pagination
          @driver.find_element(:xpath, '//ul[@class="pagination"]//li[contains(., "5")]').click
          sleep 3
        end

        if i > 7
          @driver.find_element(:xpath, '//ul[@class="pagination"]//li[contains(., "7")]').click
          sleep 3
        end

        if i > 9
          @driver.find_element(:xpath, '//ul[@class="pagination"]//li[contains(., "9")]').click
          sleep 3
        end

        if i > 11
          @driver.find_element(:xpath, '//ul[@class="pagination"]//li[contains(., "11")]').click
          sleep 3
        end

        @driver.find_element(:xpath, '//ul[@class="pagination"]//li[contains(., "' + i.to_s + '")]').click
        sleep 3
      end

      search_results = @driver.find_element(:xpath, '//div[@class="search__results__i"]')
      items = search_results.find_elements(:xpath, '//div[@class="search__place__content"]//a[@class="search__place__content__title"]')
      puts "page: #{i} -> items: #{items.size}"
      report << "page: #{i} -> items: #{items.size}"

      result_hash = {}
      items.each do |item|
        next unless item.attribute('href').present?
        property_url = item.attribute('href')
        property_id = property_url.split('/').last.split('-').first
        property_name = item.text
        result_hash[property_id] = {property_name: property_name,
                                    property_url: property_url}
      end

      result_hash.each do |key, value|
        record = Bot.where(source_cd: source, property_id: key)[0]
        puts "already scraped property id: #{key}" if record.present?

        break if total_message >= message_limit  #STOP when limit reaches

        begin
          puts value[:property_url]
          @driver.get value[:property_url]
          sleep 1

          unless record.present?
            profile_url = @driver.find_element(:xpath, '//div[@class="page__host__image"]//a').attribute('href')
            user_name = @driver.find_element(:xpath, '//div[@class="page__host__info__name"]//a').text
            user_id = profile_url.split('/').last
            address = "#{@driver.find_element(:xpath, '//table[@class="place__description__details__table"]//tr[last()-1]//th').text}, CA"
            property_type = @driver.find_element(:xpath, '//h2[@class="place__header__address"]').text.split(',').first.strip.downcase
            num_bedrooms = @driver.find_element(:xpath, '//table[@class="place__description__details__table"]//tr[4]//th').text.to_i
            num_bathrooms = @driver.find_element(:xpath, '//table[@class="place__description__details__table"]//tr[5]//th').text.to_i

            #store all scraped data
            # puts "user: #{user_id}, name: #{user_name}, property id: #{key}, property name: #{value[:property_name]}, property url: #{value[:property_url]}, profile url: #{profile_url}, address: #{address}, property type: #{property_type}, bedrooms: #{num_bedrooms}, bathrooms: #{num_bathrooms}"
            report << "user: #{user_id}, name: #{user_name}, property id: #{key}, property name: #{value[:property_name]}, property url: #{value[:property_url]}, profile url: #{profile_url}, address: #{address}, property type: #{property_type}, bedrooms: #{num_bedrooms}, bathrooms: #{num_bathrooms}"
            record = Bot.new({'host_name' => user_name,
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

          if Bot.where(source_cd: source, profile_id: record.profile_id, status_cd: 2).present? #SKIP when same host already been messaged
            puts "already messaged this host #{record.profile_id}"
            next
          end

          #book
          contact_btn = @driver.find_element(:xpath, '//a[@class="common__dialog__button__open place__host__info__button"]') rescue nil
          if contact_btn.present?
            contact_btn.click
            sleep 1
            contact_form = @driver.find_element(:xpath, '//form[@id="new_message"]')

            default_guest = 1
            guest_ddl = Selenium::WebDriver::Support::Select.new(contact_form.find_element(:xpath, '//select[@id="message_number_of_adults"]'))
            guest_ddl.options.reverse.each do |ele|
              default_guest = 2 if ele.text == '2' #pick 2 guests if available otherwise default to 1 guest
            end
            guest_ddl.select_by(:value, default_guest.to_s)
            sleep 2

            message = messages[3].gsub '|name|', record.host_name ||= 'host'
            textarea = contact_form.find_element(:xpath, '//textarea[@id="message_body"]')
            textarea.clear
            textarea.send_keys message
            sleep 3

            start_date = (Date.today + 2).strftime '%m/%d/%Y'
            end_date = (Date.today + 5).strftime '%m/%d/%Y'
            @driver.execute_script("document.getElementsByName('message[start_date]')[0].value='" + start_date + "'")
            @driver.execute_script("document.getElementsByName('message[end_date]')[0].value='" + end_date + "'")

            unless test
              contact_form.find_element(:xpath, '//input[@class="btn common__dialog__overlay__button"]').click
              sleep 1
              contact_form.find_element(:xpath, '//input[@class="btn common__dialog__overlay__button"]').click
              sleep 3
              total_message += 1
              total_all_msg += 1
              puts "contacted host #{record.host_name} for property #{record.property_name}"
              report << "contacted host #{record.host_name} for property #{record.property_name}"
              record.status = :contacted
              record.save
            else
              total_message += 1
            end
          end
        rescue Exception => e
          report << "9flats error for #{key}: #{e}"
        end
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
