module PandaConfig
  class << self
    
    def method_missing(name)
      yml[name.to_sym]
    end
    
    def yml
      config_path = Rails.root.join('config', 'panda.yml')
      @default_storage ||= YAML::load_file(config_path)[Rails.env]
      @default_storage.to_options
    rescue
      raise StandardError, "Panda config file '#{config_path}' doesn't exist."
    end
    
  end
end