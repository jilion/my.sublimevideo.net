module PandaConfig
  class << self
    
    def method_missing(name)
      yml[name.to_sym]
    end
    
    def yml
      config_path = Rails.root.join('config', 'panda.yml')
      @yml_options ||= YAML::load_file(config_path)[Rails.env]
      @yml_options.to_options
    rescue
      raise StandardError, "Panda config file '#{config_path}' doesn't exist."
    end
    
  end
end