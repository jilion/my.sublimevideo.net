module Ogone
  class << self
    
    def method_missing(name, *args)
      gateway.send(name, *args)
    end
    
  private
    
    def gateway
      @gateway ||= ActiveMerchant::Billing::OgoneGateway.new(yml)
    end
    
    def yml
      config_path = Rails.root.join('config', 'ogone.yml')
      @default_storage ||= YAML::load_file(config_path)[Rails.env]
      @default_storage.to_options
    rescue
      raise StandardError, "Ogone config file '#{config_path}' doesn't exist."
    end
    
  end
end