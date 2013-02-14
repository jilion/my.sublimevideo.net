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
      channel = PusherChannel.new(event["channel"])
      case event["name"]
      when 'channel_occupied'; channel.occupied!
      when 'channel_vacated'; channel.vacated!
      end
    end
  end

  def self.trigger(channel_name, event_name, data)
    channel = PusherChannel.new(channel_name)
    if channel.public? || channel.occupied?
      Pusher.trigger(channel.to_s, event_name, data)
      true
    else
      false
    end
  rescue Pusher::Error
    false
  end


end
