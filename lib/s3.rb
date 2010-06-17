module S3
  class << self
    
    def method_missing(name)
      yml[name.to_sym]
    end
    
    def logs_name_list(options = {})
      options['max-keys'] ||= 100
      remove_prefix = options.delete(:remove_prefix)
      keys  = logs_bucket.keys(options)
      names = keys.map! { |key| key.name }
      if remove_prefix && options['prefix']
        names.map! { |name| name.gsub(options['prefix'], '') }
        names.delete_if { |name| name.blank? }
      end
      names
    end
    
  private
    
    def logs_bucket
      @logs_bucket ||= client.bucket('sublimevideo.logs')
    end
    
    def client
      @client ||= Aws::S3.new(access_key_id, secret_access_key)
    end
    
    def yml
      config_path = Rails.root.join('config', 's3.yml')
      @default_storage ||= YAML::load_file(config_path)
      @default_storage.to_options
    rescue
      raise StandardError, "S3 config file '#{config_path}' doesn't exist."
    end
    
  end
end