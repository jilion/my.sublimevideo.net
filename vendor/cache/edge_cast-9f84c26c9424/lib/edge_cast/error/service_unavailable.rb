require 'edge_cast/error/server_error'

module EdgeCast
  # Raised when EdgeCast returns the HTTP status code 503
  class Error::ServiceUnavailable < EdgeCast::Error::ServerError
  end
end
