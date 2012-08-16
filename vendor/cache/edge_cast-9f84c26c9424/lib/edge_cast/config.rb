require 'edge_cast/version'

module EdgeCast
  # Defines constants and methods related to configuration
  module Config

    # The HTTP connection adapter that will be used to connect if none is set
    DEFAULT_ADAPTER = :net_http

    # The Faraday connection options if none is set
    DEFAULT_CONNECTION_OPTIONS = {}

    DEFAULT_HOST = 'api.edgecast.com'

    # The oauth token if none is set
    DEFAULT_API_TOKEN = nil

    # The value sent in the 'User-Agent' header if none is set
    DEFAULT_USER_AGENT = "EdgeCast Ruby Gem #{EdgeCast::VERSION}"

    # An array of valid keys in the options hash when configuring a {EdgeCast::Client}
    VALID_OPTIONS_KEYS = [
      :adapter,
      :connection_options,
      :account_number,
      :api_token,
      :user_agent
    ]

    attr_accessor *VALID_OPTIONS_KEYS

    # When this module is extended, set all configuration options to their default values
    def self.extended(base)
      base.reset
    end

    # Convenience method to allow configuration options to be set in a block
    def configure
      yield self
      self
    end

    # Create a hash of options and their values
    def options
      VALID_OPTIONS_KEYS.inject({}) { |opts, k| opts[k] = send(k); opts }
    end

    # Reset all configuration options to defaults
    def reset
      self.adapter            = DEFAULT_ADAPTER
      self.connection_options = DEFAULT_CONNECTION_OPTIONS
      self.api_token          = DEFAULT_API_TOKEN
      self.user_agent         = DEFAULT_USER_AGENT
      self
    end

  end
end
