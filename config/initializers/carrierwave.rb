require_dependency 's3'

module CarrierWave

  class << self
    def fog_configuration
      configure do |config|
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
      end
    end

    def file_configuration
      configure do |config|
        config.storage              = :file
        config.enable_processing    = true
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
