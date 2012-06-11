require_dependency 'pusher_config'

Pusher.url = PusherConfig.url if PusherConfig.url.present?
