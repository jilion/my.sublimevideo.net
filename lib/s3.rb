module S3
  class << self
    extend ActiveSupport::Memoizable
    
    def access_key_id
      yml[:access_key_id] == 'heroku_env' ? ENV['S3_ACCESS_KEY_ID'] : yml[:access_key_id]
    end
    
    def secret_access_key
      yml[:secret_access_key] == 'heroku_env' ? ENV['S3_SECRET_ACCESS_KEY'] : yml[:secret_access_key]
    end
    
    def method_missing(name)
      yml[name.to_sym]
    end
    
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
    
    def player_bucket
      client.bucket(S3Bucket.player)
    end
    memoize :player_bucket
    
    def logs_bucket
      client.bucket(S3Bucket.logs)
    end
    memoize :logs_bucket
    
    def client
      Aws::S3.new(access_key_id, secret_access_key)
    end
    memoize :client
    
    def reset_yml_options
      @yml_options = nil
    end
    
  private
    
    def yml
      config_path = Rails.root.join('config', 's3.yml')
      @yml_options ||= YAML::load_file(config_path)[Rails.env]
      @yml_options.to_options
    rescue
      raise StandardError, "S3 config file '#{config_path}' doesn't exist."
    end
    
  end
end