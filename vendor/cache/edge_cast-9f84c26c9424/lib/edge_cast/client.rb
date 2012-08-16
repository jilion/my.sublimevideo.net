require 'edge_cast/config'
require 'edge_cast/connection'
require 'edge_cast/request'

module EdgeCast
  # Wrapper for the EdgeCast REST API
  #
  # @note All methods have been separated into modules and follow the same grouping used in the EdgeCast API Documentation.
  class Client

    include EdgeCast::Connection
    include EdgeCast::Request

    require 'edge_cast/client/media'
    require 'edge_cast/client/media/cache/management'
    include EdgeCast::Client::Media::Cache::Management
    require 'edge_cast/client/media/cache/settings/compression'
    include EdgeCast::Client::Media::Cache::Settings::Compression
    require 'edge_cast/client/media/cache/settings/query_string_caching'
    include EdgeCast::Client::Media::Cache::Settings::QueryStringCaching
    require 'edge_cast/client/media/cache/settings/query_string_logging'
    include EdgeCast::Client::Media::Cache::Settings::QueryStringLogging

    require 'edge_cast/client/media/log/settings/format'
    include EdgeCast::Client::Media::Log::Settings::Format
    require 'edge_cast/client/media/log/settings/storage'
    include EdgeCast::Client::Media::Log::Settings::Storage

    require 'edge_cast/client/media/token'
    include EdgeCast::Client::Media::Token

    attr_accessor *Config::VALID_OPTIONS_KEYS

    # Initializes a new API object
    #
    # @param attrs [Hash]
    # @return [EdgeCast::Client]
    def initialize(attrs = {})
      attrs = EdgeCast.options.merge(attrs)
      Config::VALID_OPTIONS_KEYS.each do |key|
        instance_variable_set("@#{key}".to_sym, attrs[key])
      end
    end

  end
end
