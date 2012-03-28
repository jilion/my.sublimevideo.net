require 'carrierwave/processing/mime_types'

CarrierWave.configure do |config|
  case Rails.env
  when 'production', 'staging', 'development'
    config.cache_dir            = Rails.root.join('tmp/uploads')
    config.storage              = :fog
    config.s3_cnamed            = true if S3.cnamed
    config.s3_access_key_id     = S3.access_key_id
    config.s3_secret_access_key = S3.secret_access_key
    config.s3_access_policy     = :public_read
  when 'test'
    config.storage              = :file
    config.enable_processing    = false
  end
end