class CampfireWrapper
  include Configurator

  config_file 'campfire.yml'
  config_accessor :subdomain, :api_token, :default_room

  attr_reader :room

  def self.post(message, options = {})
    return unless Rails.env.in?(%w[staging production])
    wrapper = new(options[:room])
    message = "[STAGING] #{message}" if Rails.env == 'staging'
    wrapper.speak(message)
  end

  def initialize(room_name = nil)
    room_name ||= self.class.default_room
    @room = self.class.client.find_room_by_name(room_name)
  end

  def speak(message)
    room.speak(message)
  end

  private

  def self.client
    @client ||= Tinder::Campfire.new(subdomain, token: api_token)
  end

end