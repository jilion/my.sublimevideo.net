require 'tinder'

class CampfireWrapper

  attr_reader :room

  def initialize(room_name = nil)
    @room = self.class.client.find_room_by_name(room_name || ENV['CAMPFIRE_DEFAULT_ROOM'])
  end

  def speak(message)
    room.speak(message)
  end

  def self.post(message, options = {})
    return unless %w[staging production].include?(Rails.env)

    wrapper = new(options[:room])
    message = "[STAGING] #{message}" if Rails.env == 'staging'
    wrapper.speak(message)
  end

  private

  def self.client
    @@_client ||= Tinder::Campfire.new(ENV['CAMPFIRE_SUBDOMAIN'], token: ENV['CAMPFIRE_API_TOKEN'])
  end

end
