require 'edge_cast/error/client_error'

module EdgeCast
  # Raised when EdgeCast returns the HTTP status code 406
  class Error::NotAcceptable < EdgeCast::Error::ClientError
  end
end
