CarrierWave.configure do |config|
  case Rails.env
  when 'production'
    config.storage              = :s3
    config.s3_access_key_id     = 'xxxxxx'
    config.s3_secret_access_key = 'xxxxxx'
    config.s3_bucket            = 'name_of_bucket'
  when 'development'
    config.storage              = :file
  when 'test'
    config.storage              = :file
    config.enable_processing    = false
  end
end
