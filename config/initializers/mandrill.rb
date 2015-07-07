MandrillMailer.configure do |c|
  c.api_key = ENV['MANDRILL_API_KEY']

  case Rails.env
  when 'production'
    MandrillMailer.config.default_url_options = { host: 'www.hostwise.com', protocol: 'https' }
  when 'staging'
    MandrillMailer.config.default_url_options = { host: 'www.hostwise-qa.com', protocol: 'http' }
  when 'development'
    MandrillMailer.config.default_url_options = { host: ENV['HOST'], protocol: 'http' }
  end
end
