module Ogone
  class << self
    extend ActiveSupport::Memoizable
    
    def method_missing(name, *args)
      gateway.send(name, *args)
    end
    
    def yml
      config_path = Rails.root.join('config', 'ogone.yml')
      @default_storage ||= YAML::load_file(config_path)[Rails.env]
      @default_storage.to_options
    rescue
      raise StandardError, "Ogone config file '#{config_path}' doesn't exist."
    end
    
  private
    
    def gateway
      ActiveMerchant::Billing::Base.gateway_mode = :test
      Rails.logger.info ActiveMerchant::Billing::Base.gateway_mode
      ActiveMerchant::Billing::OgoneGateway.new(yml)
    end
    memoize :gateway
    
  end
end