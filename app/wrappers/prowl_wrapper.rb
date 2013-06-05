require 'prowl'

class ProwlWrapper

  API_KEYS = [
    '4f5c3597999287896a2473a817a1983866bbdc39', # Thibaud
    '1817dcfca231ac0123aa127c9ee8fe37e4dcb15d', # Zeno
    'a8019afeb0a326ab445456e2cd0ef90a5a78e57e', # Remy
  ]

  attr_reader :message

  def self.notify(message)
    new(message).notify
  end

  def initialize(message)
    @message = message
  end

  def notify
    self.class.client.add(event: 'Alert', priority: 2, description: message.to_s)
  end

  def self.client
    @@_client ||= Prowl.new(apikey: API_KEYS.join(','), application: 'MySublime')
  end

end
