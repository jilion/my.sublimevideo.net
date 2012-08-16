require 'faraday'
require 'faraday_middleware'
require 'edge_cast/request/authorization'
require 'edge_cast/response/raise_client_error'
require 'edge_cast/response/raise_server_error'

module EdgeCast
  module Connection

    def endpoint
      "https://#{EdgeCast::Config::DEFAULT_HOST}/v2/mcc/customers/#{account_number}"
    end

  private

    # Returns a Faraday::Connection object
    #
    # @param options [Hash] A hash of options
    # @return [Faraday::Connection]
    def connection(options = {})
      default_options = {
        :headers => {
          :accept => 'application/json',
          :user_agent => user_agent,
          :host => EdgeCast::Config::DEFAULT_HOST
        },
        :ssl => { :verify => false },
        :url => endpoint,
      }

      @connection ||= Faraday.new(default_options.merge(connection_options)) do |builder|
        builder.request :auth, api_token
        builder.request :json
        builder.request :multipart
        builder.request :url_encoded

        builder.response :client_error
        builder.response :json
        builder.response :server_error

        builder.adapter(adapter)
      end
    end
  end
end
