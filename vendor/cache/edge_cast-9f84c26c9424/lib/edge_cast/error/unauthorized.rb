require 'edge_cast/error/client_error'

module EdgeCast
  # Raised when EdgeCast returns the HTTP status code 401
  class Error::Unauthorized < EdgeCast::Error::ClientError
  end
end
