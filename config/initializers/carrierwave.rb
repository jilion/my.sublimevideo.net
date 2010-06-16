s3_config = YAML::load_file(Rails.root.join('config', 's3.yml')).to_options

CarrierWave.configure do |config|
  case Rails.env
  when 'production'
    config.cache_dir            = Rails.root.join('tmp/uploads')
    config.storage              = :s3
    config.s3_cnamed            = true if s3_config[:cnamed]
    config.s3_access_key_id     = s3_config[:access_key_id]
    config.s3_secret_access_key = s3_config[:secret_access_key]
    config.s3_access_policy     = 'private'
  when 'development'
    config.storage              = :file
  when 'test'
    config.storage              = :file
    config.enable_processing    = false
  end
end