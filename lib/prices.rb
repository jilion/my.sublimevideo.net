module Prices
  class << self
    
    def method_missing(name)
      yml[name.to_sym]
    end
    
  private
    
    def yml
      config_path = Rails.root.join('config', 'prices.yml')
      @yml_options ||= YAML::load_file(config_path)[Rails.env]
      @yml_options.to_options
    rescue
      raise StandardError, "Prices config file '#{config_path}' doesn't exist."
    end
    
  end
end