module Notify
  class << self

    def send(message, options = {})
      hoptoad(message, options)
      prowl(message) if Rails.env.production? || Rails.env.staging?
    end

  private

    def hoptoad(message, options)
      if options[:exception]
        HoptoadNotifier.notify(:error_message => message + " // exception: #{options[:exception]}")
      else
        HoptoadNotifier.notify(:error_message => message)
      end
    end

    def prowl(message)
      @prowl ||= Prowl.new(
        :apikey => prowl_api_keys.join(","),
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