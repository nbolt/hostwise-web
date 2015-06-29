require 'spec_helper'
require 'selenium-webdriver'

describe 'flipkey' do
  include ActionView::Helpers::TextHelper

  def send_report(type, report)
    UserMailer.report("flipkey #{type}", simple_format(report.join('<br>')), 'andre@hostwise.com').then(:deliver)
  end

  def source
    4
  end

  it 'create account', type: 'signup' do
    report = []
    account_limit = ENV['account_limit'].to_i
    report << "creating #{account_limit} accounts..."

    account_limit.times do
      first_name = ['michelle', 'michal', 'donna', 'jeann', 'carol'].sample
      last_name = ['wong', 'lee', 'chin', 'chan', 'li'].sample

      email = "#{ENV['base_email']}+#{Random.new.rand(1...10000)}@gmail.com"
      while BotAccount.where(email: email, source_cd: source).present?
        email = "#{ENV['base_email']}+#{Random.new.rand(1...10000)}@gmail.com"
      end
      pwd = 'airbnb338'

      begin
        acct = BotAccount.new({'email' => email,
                               'password' => pwd,
                               'status' => :active,
                               'source_cd' => source,
                               'last_run' => Date.yesterday})
        acct.save
        puts "flipkey account created: #{email}"
        report << "flipkey account created: #{email}"
        sleep 3
      rescue Exception => e
        report << e
      end
    end

    send_report 'signup', report
  end

  it 'scrape and book properties', type: 'scrape_and_book' do
    report = []
    use_proxy = ENV['proxy'] == 'true'
    test = ENV['test'] == 'true'
    start_page = ENV['start_page'].present? ? ENV['start_page'].to_i : 1
    month_limit = 5
    message_limit = ENV['message_limit'].to_i
    account_limit = ENV['account_limit'].to_i
    total_all_msg = 0

    messages = ["Hey |name|!\n\nI love your vacation rental. You should check out HostWise.com, (first clean free) I use them and if I refer a free service then I get another free service! :) You can do the same!",
                "Hey |name|!\n\nLooks like your vacation rental would be a perfect fit for our company, HostWise.com. Our company was created by hosts, for hosts. We automate the entire home turnover for you and guarantee a 5 star clean rating every time. Give us a try for first time for free, no strings attached. Not sure if you have many more properties, but if so we do offer enterprise pricing discounts as well! :)",
                "Hey |name|!\n\nI just started using HostWise.com to clean and turnover my property and think your property would be a perfect fit for them too. First service is free, no strings attached, I just got a coupon code for 10% off 3 services if your are interested I can give it to you!\n\nCheers!",
                "Hi |name|!\n\nDo you use HostWise.com to clean and restock your property? The last rental we booked in LA did and the presentation was hotel caliber - from linens and towels to toiletries just for the guests. They're still doing FREE TRIALS at HostWise.com, by the way.\n\nCoupon code: TRYHOSTWISE100\n\nCheers!",
                "Hi |name|,\n\nDo you use HostWise.com for housekeeping, linens, towels?"]

    driver = Selenium::WebDriver.for :chrome
    if use_proxy
      server = BrowserMob::Proxy::Server.new ENV['BROWSERMOB']
      server.start
      proxy = Selenium::WebDriver::Proxy.new(http: server.create_proxy.selenium_proxy.http)
      caps = Selenium::WebDriver::Remote::Capabilities.chrome(proxy: proxy)
      driver = Selenium::WebDriver.for(:chrome, desired_capabilities: caps)
    end
    site = 'https://www.flipkey.com'

    location = URI.unescape ENV['location']
    puts "scraping properties at #{location}..."
    report << "scraping properties at #{location}..."

    accounts = BotAccount.where('status_cd = 1 and source_cd = ? and last_run < ?', source, Date.today).limit(account_limit)
    report << "accounts: #{accounts.count}"
    accounts.each do |account|
      username = account.email
      puts "logging into account: #{username}"
      driver.navigate.to site

      start_date = (Date.today + 2).strftime '%m/%d/%Y'
      end_date = (Date.today + 5).strftime '%m/%d/%Y'
      search_form = driver.find_element(:xpath, '//form[@id="vr-search"]')
      search_form.find_element(:xpath, '//input[@id="vr-location"]').send_keys location
      driver.execute_script("document.getElementsByName('data[search][check-in]')[0].value='" + start_date + "'")
      driver.execute_script("document.getElementsByName('data[search][check-out]')[0].value='" + end_date + "'")
      search_form.submit
      sleep 5

      #loop through each result
      base_url = driver.current_url
      pages = driver.find_elements(:xpath, '//div[@class="search-pagination"]//a[@class="search-page-number button-grey"]')
      last_page = pages.last.text.to_i
      total_message = 0
      puts "#{base_url}, #{start_page}, #{last_page}"
      (start_page..last_page).each do |i|
        puts "#{base_url}?page=#{i}"
        driver.navigate.to "#{base_url}?page=#{i}"
        sleep 1

        items = driver.find_elements(:xpath, '//div[@id="property-list"]//div[@class="property-photo-summary"]')
        puts "page: #{i} -> items: #{items.size}"
        report << "page: #{i} -> items: #{items.size}"

        result_hash = {}
        items.each do |item|
          next unless item.attribute('data-href')
          property_url = "#{site}#{item.attribute('data-href').gsub(/\/$/, '')}"
          property_id = property_url.split('/').last
          property_name = item.attribute('data-title')
          result_hash[property_id] = {property_name: property_name,
                                      property_url: property_url}
        end

        result_hash.each do |key, value|
          record = Bot.where(source_cd: source, property_id: key)[0]
          puts "already scraped property id: #{key}" if record.present?

          break if total_message >= message_limit  #STOP when limit reaches

          begin
            puts value[:property_url]
            driver.get value[:property_url]
            sleep 3

            unless record.present?
              profile_url = driver.find_element(:xpath, '//div[@id="pdp-owner-box"]//a[@class="button-md button-grey"]').attribute('href').gsub(/\/$/, '')
              user_id = profile_url.split('/')[-2]
              user_name = driver.find_element(:xpath, '//div[@id="pdp-owner-box"]//h3[@class="hidden-xs"]').text
              address = driver.find_element(:xpath, '//div[@id="map_header"]//span[@class="loc_approx"]').text

              property_type = 'unknown'
              num_bedrooms = 0
              num_bathrooms = 0
              features = driver.find_elements(:xpath, '//div[@id="property-details"]//p[@class="property-desciption-detail"]')
              features.each do |feature|
                parts = feature.text.split(' ')
                if parts.include?('House') || parts.include?('Condo') || parts.include?('Studio') || parts.include?('Villa') || parts.include?('Townhouse') || parts.include?('Bungalow')
                  property_type = parts.first.downcase
                elsif parts.include?('Bedrooms')
                  num_bedrooms = parts.last.to_i
                elsif parts.include?('Bathrooms')
                  num_bathrooms = parts.last.to_i
                end
              end

              #store all scraped data
              # puts "user: #{user_id}, name: #{user_name}, property id: #{key}, property name: #{value[:property_name]}, property url: #{value[:property_url]}, profile url: #{profile_url}, address: #{address}, property type: #{property_type}, bedrooms: #{num_bedrooms}, bathrooms: #{num_bathrooms}"
              report << "user: #{user_id}, name: #{user_id}, property id: #{key}, property name: #{value[:property_name]}, property url: #{value[:property_url]}, profile url: #{profile_url}, address: #{address}, property type: #{property_type}, bedrooms: #{num_bedrooms}, bathrooms: #{num_bathrooms}"
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
              record.save unless test
            end

            if Bot.where(source_cd: source, profile_id: record.profile_id, status_cd: 2).present? #SKIP when same host already been messaged
              puts "already messaged this host #{record.profile_id}"
              next
            end

            #book
            driver.find_element(:xpath, '//div[@id="pdp-owner-box"]//button[@class="button-orange button-md"]').click
            sleep 1
            contact_form = driver.find_element(:xpath, '//form[@id="inquiry_modal_form"]')

            default_guest = 1
            guest_ddl = Selenium::WebDriver::Support::Select.new(contact_form.find_element(:xpath, '//select[@id="f-guests"]'))
            guest_ddl.options.reverse.each do |ele|
              default_guest = 2 if ele.text.split(' ').first == '2' #pick 2 guests if available otherwise default to 1 guest
            end
            guest_ddl.select_by(:value, default_guest.to_s)
            sleep 2

            first_name = ['michelle', 'michal', 'donna', 'jeann', 'carol'].sample
            last_name = ['wong', 'lee', 'chin', 'chan', 'li'].sample
            name_input = contact_form.find_element(:xpath, '//input[@id="modal_inquiry_name"]')
            name_input.clear
            name_input.send_keys "#{first_name.capitalize} #{last_name.capitalize}"
            sleep 2

            email_input = contact_form.find_element(:xpath, '//input[@id="modal_inquiry_email"]')
            email_input.clear
            email_input.send_keys account.email
            sleep 1

            message = messages[3].gsub '|name|', record.host_name ||= 'host'
            textarea = contact_form.find_element(:xpath, '//textarea[@id="modal_inquiry_message"]')
            textarea.clear
            textarea.send_keys message
            sleep 3

            unless test
              contact_form.find_element(:xpath, '//button[@id="inquiry-button"]').click
              sleep 3
              captcha = contact_form.find_element(:xpath, '//div[@id="captcha_display_div"]') rescue nil
              if captcha.present?
                puts "rate limit met: #{username}"
                report << "rate limit met: #{username}"
                total_message = message_limit
                break
              else
                total_message += 1
                total_all_msg += 1
                puts "contacted host #{record.host_name} for property #{record.property_name}"
                report << "contacted host #{record.host_name} for property #{record.property_name}"
                record.status = :contacted
                record.save
              end
            else
              total_message += 1
            end
          rescue Exception => e
            puts "flipkey error for #{key}: #{e}"
            report << "flipkey error for #{key}: #{e}"
          end
        end

        if total_message >= message_limit  #STOP when limit reaches
          puts "next run starts at page:#{i}"
          report << "next run starts at page:#{i}"
          start_page = i
          break
        end
      end

      puts "total sent: #{total_all_msg}"
      report << "total sent: #{total_all_msg}"

      driver.navigate.to site
      sleep 2
    end

    driver.quit
    server.stop if use_proxy
    send_report 'scrape', report
  end
end
