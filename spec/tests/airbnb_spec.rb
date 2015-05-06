require 'spec_helper'
require 'selenium-webdriver'

describe 'run' do
  #command: user=jman8615@gmail.com pwd=jman8615! rspec spec/tests/airbnb_spec.rb
  username = ENV['user']
  password = ENV['pwd']
  site = 'https://www.airbnb.com'

  driver = Selenium::WebDriver.for :chrome
  driver.navigate.to site

  #login
  driver.find_element(:xpath, '//li[@id="login"]//a').click
  sleep 1
  login_form = driver.find_element(:xpath, '//form[@class="signin-form login-form"]')
  login_form.find_element(:xpath, '//input[@id="signin_email"]').send_keys username
  login_form.find_element(:xpath, '//input[@id="signin_password"]').send_keys password
  login_form.submit
  sleep 1

  #search
  location = 'Los Angeles, CA, United States'
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
    puts "page: #{i} -> items: #{items.size}"

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
      #skip if already been contacted
      next if Bot.where(source_cd: 0, status_cd: 2, profile_id: value[:user_id], property_id: key).present?

      begin
        driver.get value[:property_url]
        sleep 1

        superhost = driver.find_element(:xpath, '//div[@id="superhost-badge-profile"]') rescue nil
        user_name = driver.find_element(:xpath, '//div[@id="host-profile"]//div[@class="row"]//div[@class="col-lg-8"]//h4').text.split(',').last.strip

        #click contact host button
        driver.find_element(:xpath, '//button[@id="host-profile-contact-btn"]').click
        sleep 3
        contact_form = driver.find_element(:xpath, '//form[@id="message_form"]')

        #set guest - some properties will have only 1 guest option
        Selenium::WebDriver::Support::Select.new(contact_form.find_element(:xpath, '//select[@id="message_number_of_guests"]')).select_by(:value, '1')

        #set message
        message = "Hello #{user_name}, \n\nplease visit google.com"
        textarea = contact_form.find_element(:xpath, '//textarea[@id="question"]')
        textarea.clear
        textarea.send_keys message

        #pick checkin date
        contact_form.find_element(:xpath, '//input[@id="message_checkin"]').click
        sleep 1
        calendar = contact_form.find_element(:xpath, '//div[@class="ui-datepicker ui-widget ui-widget-content ui-helper-clearfix ui-corner-all"]//table[@class="ui-datepicker-calendar"]//tbody')
        available_dates = calendar.find_elements(:xpath, '//a[@class="ui-state-default"]') rescue nil
        if available_dates.present?
          # puts "checkin date: #{available_dates[available_dates.length - 3].text}"
          available_dates.first.click
        end

        #pick checkout date - the system automatically pick the next checkout date if you select a checkin date.

        #IMPORTANT: send message (uncomment only if you know what you are doing)
        #contact_form.submit
        #sleep 3

        #store all scraped data
        puts "user: #{value[:user_id]}, name: #{user_name}, property id: #{key}, property name: #{value[:property_name]}, property url: #{value[:property_url]}, profile url: #{value[:profile_url]}, superhost: #{superhost.present?}"
        bot = Bot.new({'host_name' => user_name,
                       'profile_id' => value[:user_id],
                       'profile_url' => value[:property_url],
                       'property_id' => key,
                       'property_name' => value[:property_name],
                       'property_url' => value[:property_url],
                       'status' => :active,
                       'source' => :airbnb,
                       'super_host' => superhost.present?})
        bot.save

      rescue Exception => e
        Rails.logger.error "AirBnb error for #{key} #{value}: #{e}"
      end
    end
  end

  driver.quit
end
