module S3
  class << self
    
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
      remove_prefix = options.delete(:remove_prefix)
      keys  = logs_bucket.keys(options)
      names = keys.map! { |key| key.name }
      if remove_prefix && options['prefix']
        names.map! { |name| name.gsub(options['prefix'], '') }
        names.delete_if { |name| name.blank? }
      end
      names
    end
    
    def panda_bucket
      @panda_bucket ||= client.bucket(S3Bucket.panda)
    end
    
    def videos_bucket
      @videos_bucket ||= client.bucket(S3Bucket.videos)
    end
    
    def reset_yml_options
      @yml_options = nil
    end
    
  private
    
    def logs_bucket
      @logs_bucket ||= client.bucket(S3Bucket.logs)
    end
    
    def client
      @client ||= Aws::S3.new(access_key_id, secret_access_key)
    end
    
    def yml
      config_path = Rails.root.join('config', 's3.yml')
      @yml_options ||= YAML::load_file(config_path)[Rails.env]
      @yml_options.to_options
    rescue
      raise StandardError, "S3 config file '#{config_path}' doesn't exist."
    end
    
  end
end