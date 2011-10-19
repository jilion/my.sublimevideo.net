module Notify
  include Configurator

  heroku_config_file 'prowl.yml'

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
        :apikey => yml_options[:api_keys].join(","),
        :application => "MySublime"
      )
      @prowl.add(
        :event => "Alert",
        :priority => 2,
        :description => message
      )
    end

  end

end
