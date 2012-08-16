require 'edge_cast/error/client_error'

module EdgeCast
  # Raised when EdgeCast returns the HTTP status code 404
  class Error::NotFound < EdgeCast::Error::ClientError
  end
end
