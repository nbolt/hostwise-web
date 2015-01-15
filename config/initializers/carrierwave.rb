CarrierWave.configure do |config|
  config.fog_credentials = {
    provider: 'AWS',
    aws_access_key_id: ENV['AWS_ACCESS_KEY_ID'],
    aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
    region: 'us-east-1'
  }
  config.fog_directory = "porter-for-hosts-#{Rails.env}"
  config.fog_public = true

  if Rails.env.test? || Rails.env.development?
    config.storage = :file
    config.enable_processing = false
  else
    config.storage = :fog
  end
end
