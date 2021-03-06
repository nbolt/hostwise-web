CarrierWave.configure do |config|
  if Rails.env.test? || Rails.env.development?
    config.storage = :file
    config.enable_processing = true
  else
    config.storage = :fog
  end
  config.fog_credentials = {
    provider: 'AWS',
    aws_access_key_id: ENV['AWS_ACCESS_KEY_ID'],
    aws_secret_access_key: ENV['AWS_SECRET_ACCESS_KEY'],
    region: ENV['S3_BUCKET']
  }
  config.fog_directory = "hostwise-#{Rails.env}"
  config.fog_public = true
  config.use_action_status = true
end
