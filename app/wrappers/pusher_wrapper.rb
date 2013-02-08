require 'configurator'

class PusherWrapper
  include Configurator

  config_file     'pusher.yml'
  config_accessor :url

  def self.key
    url.match(/^http:\/\/(\w*):.*$/)[1]
  end

  def self.authenticated_response(channel_name, custom_data)
    Pusher[channel_name].authenticate(custom_data)
  end

  def self.handle_webhook(webhook)
    webhook.events.each do |event|
      case event["name"]
      when 'channel_occupied'
        Sidekiq.redis { |con| con.sadd("pusher:channels", event["channel"]) }
      when 'channel_vacated'
        Sidekiq.redis { |con| con.srem("pusher:channels", event["channel"]) }
      end
    end
  end

  def self.trigger(channel_name, event_name, data)
    if Sidekiq.redis { |con| con.sismember("pusher:channels", channel_name) }
      Pusher.trigger(channel_name, event_name, data)
      true
    else
      false
    end
  rescue Pusher::Error
    false
  end

end
