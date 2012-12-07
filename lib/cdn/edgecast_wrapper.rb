require_dependency 'configurator'
require 'tempfile'

module CDN
  module EdgeCastWrapper
    include Configurator

    config_file 'edgecast.yml'
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
end
