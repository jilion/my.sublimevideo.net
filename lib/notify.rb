module Notify
  class << self
    
    def send(message)
      HoptoadNotifier.notify(:error_message => message)
      prowl(message)
    end
    
  private
    
    def prowl(message)
      @prowl ||= Prowl.new(
        :apikey => prowl_api_keys,
        :application => "MySublime"
      )
      @prowl.add(
        :event => "Alert",
        :priority => 2,
        :description => message
      )
    end
    
    def prowl_api_keys
      config_path = Rails.root.join('config', 'prowl.yml')
      @api_keys ||= YAML::load_file(config_path)
    rescue
      raise StandardError, "Prowl config file '#{config_path}' doesn't exist."
    end
    
  end
end