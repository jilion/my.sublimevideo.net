module S3Wrapper
  include Configurator

  config_file 's3.yml'
  config_accessor :access_key_id, :secret_access_key

  class << self

    def bucket_url(bucket)
      "https://s3.amazonaws.com/#{bucket}/"
    end

    def fog_connection
      @fog_connection ||= Fog::Storage.new(
        provider:              'AWS',
        aws_access_key_id:     access_key_id,
        aws_secret_access_key: secret_access_key,
        region:                'us-east-1'
      )
    end

  end
end
