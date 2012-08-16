require 'edge_cast/error/client_error'

module EdgeCast
  # Raised when EdgeCast returns the HTTP status code 403
  class Error::Forbidden < EdgeCast::Error::ClientError
  end
end
