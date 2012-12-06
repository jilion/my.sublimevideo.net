require 'uri'

ActiveSupport::Notifications.subscribe 'request.active_resource' do |*args|
  event = ActiveSupport::Notifications::Event.new(*args)
  # data available:
  #   event.payload[:method]
  #   event.payload[:request_uri]
  #   event.payload[:result]

  status_code = event.payload[:result].code.to_i
  site = URI.parser.parse(event.payload[:request_uri])

  Librato.increment "active_resource.request.#{status_code}", source: site.host
end
