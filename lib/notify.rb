require_dependency 'configurator'

module Notify
  include Configurator

  config_file 'prowl.yml'

  class << self

    def send(message, options = {})
      airbrake(message, options)
      prowl(message) if Rails.env.production? || Rails.env.staging?
    end

  private

    def airbrake(message, options)
      if options[:exception]
        Airbrake.notify(Exception.new(message + " // exception: #{options[:exception]}"))
      else
        Airbrake.notify(Exception.new(message))
      end
    end

    def prowl(message)
      @prowl ||= Prowl.new(
        apikey: yml_options[:api_keys].join(","),
        application: "MySublime"
      )
      @prowl.add(
        event: "Alert",
        priority: 2,
        description: message
      )
    end

  end

end
