require 'carrierwave/processing/mime_types'

CarrierWave.configure do |config|
  case Rails.env
  when 'production', 'staging', 'development'
    config.cache_dir       = Rails.root.join('tmp/uploads')
    config.storage         = :fog
    config.fog_public      = true
    config.fog_attributes  = {}
    config.fog_credentials = {
      :provider               => 'AWS',
      :aws_access_key_id      => S3.access_key_id,
      :aws_secret_access_key  => S3.secret_access_key,
      :region                 => 'us-east-1'
    }
  when 'test'
    config.storage              = :file
    config.enable_processing    = false
  end
end