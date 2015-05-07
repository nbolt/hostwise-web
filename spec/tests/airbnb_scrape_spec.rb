require 'spec_helper'
require 'selenium-webdriver'
require 'browsermob/proxy'

describe 'run' do
  server = BrowserMob::Proxy::Server.new ENV['browsermob']
  server.start
  proxy = Selenium::WebDriver::Proxy.new(http: server.create_proxy.selenium_proxy.http)
  caps = Selenium::WebDriver::Remote::Capabilities.chrome(proxy: proxy)
  driver = Selenium::WebDriver.for(:chrome, desired_capabilities: caps)
  site = 'https://www.airbnb.com'
  driver.navigate.to site

  #search
  search_form = driver.find_element(:xpath, '//form[@id="search_form"]')
  search_form.find_element(:xpath, '//input[@id="location"]').send_keys ENV['location']
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

    puts "hash count: #{result_hash.count}"
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
        puts "user: #{value[:user_id]}, name: #{user_name}, property id: #{key}, property name: #{value[:property_name]}, property url: #{value[:property_url]}, profile url: #{value[:profile_url]}, superhost: #{superhost.present?}, address: #{address}, property type: #{property_type}, bedrooms: #{num_bedrooms}, bathrooms: #{num_bathrooms}, beds: #{num_beds}"
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
        puts "AirBnb error for #{key} #{value}: #{e}"
      end
    end
  end

  driver.quit
end
