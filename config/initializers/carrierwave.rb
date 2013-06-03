module CarrierWave
  class << self
    def fog_configuration
      configure do |config|
        config.cache_dir       = Rails.root.join('tmp/uploads')
        config.storage         = :fog
        config.fog_public      = true
        config.fog_attributes  = {}
        config.fog_credentials = {
          provider:              'AWS',
          aws_access_key_id:     ENV['S3_ACCESS_KEY_ID'],
          aws_secret_access_key: ENV['S3_SECRET_ACCESS_KEY'],
          region:                'us-east-1'
        }
      end
    end

    def file_configuration
      configure do |config|
        config.storage           = :file
        config.enable_processing = true
      end
    end
  end
end

case Rails.env
when 'production', 'staging', 'development'
  CarrierWave.fog_configuration
when 'test'
  CarrierWave.file_configuration
end
