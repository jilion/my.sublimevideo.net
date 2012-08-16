require 'edge_cast/error/server_error'

module EdgeCast
  # Raised when EdgeCast returns the HTTP status code 500
  class Error::InternalServerError < EdgeCast::Error::ServerError
  end
end
