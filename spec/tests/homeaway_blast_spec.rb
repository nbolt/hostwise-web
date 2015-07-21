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

def login(username, password)
  login_form = @driver.find_element(:xpath, '//form[@id="login-form"]')
  login_form.find_element(:xpath, '//input[@id="username"]').send_keys username
  login_form.find_element(:xpath, '//input[@id="password"]').send_keys password
  login_form.submit
  sleep 5
end

def source
  1
end

run do
  report = []
  start_page = 1
  message_limit = 5
  account_limit = 2
  total_all_msg = 0
  test = false

  messages = ["Hey |name|!\n\nI love your vacation rental. You should check out HostWise.com, (first clean free) I use them and if I refer a free service then I get another free service! :) You can do the same!",
              "Hey |name|!\n\nLooks like your vacation rental would be a perfect fit for our company, HostWise.com. Our company was created by hosts, for hosts. We automate the entire home turnover for you and guarantee a 5 star clean rating every time. Give us a try for first time for free, no strings attached. Not sure if you have many more properties, but if so we do offer enterprise pricing discounts as well! :)",
              "Hey |name|!\n\nI just started using HostWise.com to clean and turnover my property and think your property would be a perfect fit for them too. First service is free, no strings attached, I just got a coupon code for 10% off 3 services if your are interested I can give it to you!\n\nCheers!",
              "Hi |name|!\n\nDo you use HostWise.com to clean and restock your property? The last rental we booked in LA did and the presentation was hotel caliber - from linens and towels to toiletries just for the guests. They're still doing FREE TRIALS at HostWise.com, by the way.\n\nCoupon code: TRYHOSTWISE100\n\nCheers!",
              "Hi |name|,\n\nDo you use HostWise.com for housekeeping, linens, towels?"]

  site = 'https://www.homeaway.com'

  location = URI.unescape 'Los Angeles County, California'
  puts "scraping properties at #{location}..."
  report << "scraping properties at #{location}..."

  accounts = BotAccount.where('status_cd = 1 and source_cd = ? and last_run < ?', source, Date.today).limit(account_limit)
  report << "accounts: #{accounts.count}"
  accounts.each do |account|
    username = account.email
    password = account.password
    puts "logging into account: #{username}"
    @driver.navigate.to 'https://cas.homeaway.com/auth/homeaway/login?service=https%3A%2F%2Fwww.homeaway.com%2Fuser%2Fsso%2Fauth%3Flt%3Dtraveler%26context%3Ddef%26service%3D%252F'

    login username, password

    search_form = @driver.find_element(:xpath, '//form[@name="searchForm"]')
    search_form.find_element(:xpath, '//input[@id="searchKeywords"]').send_keys location
    search_form.find_element(:xpath, '//button[@type="button"]').click
    sleep 5

    #loop through each result
    total_message = 0
    base_url = @driver.current_url
    per_page = 30
    total = @driver.find_element(:xpath, '//div[@class="pager pager-right server-side-pager pager-gt-search"]//li[@class="page"]').text.split('of').last.strip.remove(',').to_i
    last_page = (total.to_f / per_page.to_f).ceil.to_i
    puts "#{base_url}, #{per_page}, #{total}, #{start_page}, #{last_page}"
    (start_page..last_page).each do |i|
      puts "#{base_url}/page:#{i}"
      @driver.navigate.to "#{base_url}/page:#{i}"
      sleep 1

      collection = @driver.find_element(:xpath, '//div[@class="js-listHitCollectionView preview-container hits js-hits"]')
      listings = collection.find_elements(:xpath, '//h3[@class="hit-headline"]//a[@class="hit-url js-hitLink"]')
      if listings.size == 0
        listings = collection.find_elements(:xpath, '//h3[@class="listing-title"]//a[@class="listing-url js-hitLink"]')
      end
      puts "page: #{i} -> listings: #{listings.size}"
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
        record = Bot.where(source_cd: source, property_id: key)[0]
        puts "already scraped property id: #{key}" if record.present?

        break if total_message >= message_limit  #STOP when limit reaches

        #begin
          puts value[:property_url]
          @driver.get value[:property_url]
          sleep 1

          unless record.present?
            address = ''
            list = @driver.find_elements(:xpath, '//ol[@class="breadcrumb breadcrumb-gt-header hidden-phone"]//li[@itemtype="http://data-vocabulary.org/Breadcrumb"]')
            list = list[2..-1]
            list.reverse.each_with_index do |l, index|
              address += (index > 0 ? ', ' : '') + l.text.delete('>')
            end
            user_name = @driver.find_element(:xpath, '//div[@class="about-the-owner"]//span[@class="owner-name"]').text rescue nil
            property_type = ''
            num_bedrooms = 0
            num_bathrooms = 0
            table = @driver.find_elements(:xpath, '//table[@class="table table-striped amenity-table"]').first
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
            record = Bot.new({'host_name' => user_name,
                              'property_id' => key,
                              'property_name' => value[:property_name],
                              'property_url' => value[:property_url],
                              'property_type' => property_type,
                              'num_bedrooms' => num_bedrooms,
                              'num_bathrooms' => num_bathrooms,
                              'status' => :active,
                              'source_cd' => source,
                              'address' => address,
                              'super_host' => false})
            record.save
          end

          if Bot.where('source_cd = ? and host_name = ? and last_contacted > ?', source, record.host_name, Date.today - 7.days).present? #SKIP when same host already been messaged recently
            puts "already messaged this host #{record.host_name}"
            next
          end

          #book
          contact_btn = @driver.find_element(:xpath, '//a[@class="btn-inquiry-link cta btn btn-inquiry js-emailOwnerButton btn-link"]') rescue nil
          if contact_btn.present?
            contact_btn.click
          else
            contact_btn = @driver.find_element(:xpath, '//a[@class="btn-inquiry-button cta btn btn-inquiry js-emailOwnerButton btn-primary cta-primary"]') rescue nil
            if contact_btn.present?
              contact_btn.click
            else
              contact_btn = @driver.find_element(:xpath, '//div[@class="owner-contact-box"]//a[@class="js-emailOwnerButton"]') rescue nil
              if contact_btn.present?
                contact_btn.click
              else
                next
              end
            end
          end
          sleep 3

          booking_form = @driver.find_element(:xpath, '//form[@id="propertyInquiryForm"]')
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
          sleep 5
          unless test
            alert = booking_form.find_element(:xpath, '//div[@id="inquiry-error"]') rescue nil
            if alert.present?
              puts "deactivated property #{record.property_name}"
              report << "deactivated property #{record.property_name}"
              record.status = :deleted
              record.save
            else
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

        # rescue Exception => e
        #   report << "HomeAway error for #{key}: #{e}"
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
