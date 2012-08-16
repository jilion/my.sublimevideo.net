require 'edge_cast/client'
require 'edge_cast/config'

module EdgeCast
  extend Config
  class << self
    # Alias for EdgeCast::Client.new
    #
    # @return [EdgeCast::Client]
    def new(options = {})
      EdgeCast::Client.new(options)
    end

    # Delegate to EdgeCast::Client
    def method_missing(method, *args, &block)
      return super unless new.respond_to?(method)
      new.send(method, *args, &block)
    end

    def respond_to?(method, include_private=false)
      new.respond_to?(method, include_private) || super(method, include_private)
    end
  end
end
