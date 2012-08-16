require 'edge_cast/error/server_error'

module EdgeCast
  # Raised when EdgeCast returns the HTTP status code 502
  class Error::BadGateway < EdgeCast::Error::ServerError
  end
end
