require_dependency 'configurator'

class ProwlWrapper
  include Configurator

  config_file 'prowl.yml'

  class << self
    def notify(message)
      prowl_client.add(
        event: "Alert",
        priority: 2,
        description: message.to_s
      )
    end

    def prowl_client
      @prowl_client ||= Prowl.new(
        apikey: ProwlWrapper.api_keys.join(","),
        application: "MySublime"
      )
    end
  end

end
