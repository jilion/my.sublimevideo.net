module EdgeCast
  # Custom error class for rescuing from all EdgeCast errors
  class Error < StandardError
    attr_reader :http_headers

    # Initializes a new Error object
    #
    # @param message [String]
    # @param http_headers [Hash]
    # @return [EdgeCast::Error]
    def initialize(message, http_headers)
      @http_headers = Hash[http_headers]
      super(message)
    end

  end
end
