require 'edge_cast'

class EdgeCastWrapper

  attr_reader :path

  def initialize(path)
    @path = path
  end

  def purge
    self.class.client.purge(:http_small_object, "http://#{ENV['EDGECAST_CNAME']}#{path}")
    Librato.increment 'cdn.purge', source: 'edgecast'
  end

  def self.purge(path)
    new(path).purge
  end

  def self.client
    @@_client ||= EdgeCast.new(account_number: ENV['EDGECAST_ACCOUNT_NUMBER'], api_token: ENV['EDGECAST_API_TOKEN'])
  end

end
