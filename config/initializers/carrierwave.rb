CarrierWave.configure do |config|
  config.fog_credentials = {
    :provider                         => 'Google',
    :google_storage_access_key_id     => 'GOOGJE72MYT5FOGRN5LR',
    :google_storage_secret_access_key => 'n3jEIkM87B5stb+6oublI244omXZ/2RWVahRYmEd'
  }
  config.fog_directory = 'porter-assets'
  if Rails.env.test? || Rails.env.development?
    config.storage = :file
    config.enable_processing = false
  else
    config.storage = :fog
  end
end
