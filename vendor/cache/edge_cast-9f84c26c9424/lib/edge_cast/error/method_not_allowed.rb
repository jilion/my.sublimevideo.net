require 'edge_cast/error/client_error'

module EdgeCast
  # Raised when EdgeCast returns the HTTP status code 405
  class Error::MethodNotAllowed < EdgeCast::Error::ClientError
  end
end
