CarrierWave.configure do |config|
  case Rails.env
  when 'production'
    config.cache_dir            = Rails.root.join('tmp/uploads')
    config.storage              = :s3
    config.s3_access_key_id     = 'AKIAJ5AJKU32OXUZAC7A'
    config.s3_secret_access_key = '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'
    config.s3_bucket            = 'sublimevideo'
    config.s3_access_policy     = 'private'
  when 'development'
    config.storage              = :file
  when 'test'
    config.storage              = :file
    config.enable_processing    = false
  end
end