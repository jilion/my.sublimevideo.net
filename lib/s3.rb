require_dependency 'configurator'

module S3
  include Configurator

  config_file 's3.yml'
  config_accessor :access_key_id, :secret_access_key

  class << self

    def logs_name_list(options = {})
      keys_names(logs_bucket, options)
    end

    def keys_names(bucket, options = {})
      remove_prefix = options.delete(:remove_prefix)
      keys  = bucket.keys(options)
      names = keys.map! { |key| key.name }
      if remove_prefix && options['prefix']
        names.map! { |name| name.gsub(options['prefix'], '') }
        names.delete_if { |name| name.blank? || name == '/' }
      end
      names
    end

    def sublimevideo_bucket
      @sublimevideo_bucket ||= client.bucket(buckets['sublimevideo'])
    end

    def player_bucket
      @player_bucket ||= client.bucket(buckets['player'])
    end

    def logs_bucket
      @logs_bucket ||= client.bucket(buckets['logs'])
    end

    def client
      @client ||= Aws::S3.new(access_key_id, secret_access_key)
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
