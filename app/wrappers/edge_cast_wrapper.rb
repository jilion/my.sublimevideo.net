require 'tempfile'

module EdgeCastWrapper
  include Configurator

  config_file 'edge_cast.yml'
  config_accessor :account_number, :api_token

  class << self

    def purge(path)
      client.purge(:http_small_object, "http://#{cname}#{path}")
      Librato.increment 'cdn.purge', source: 'edgecast'
    end

  private

    def client
      @client ||= EdgeCast.new(account_number: account_number, api_token: api_token)
    end

  end

end
