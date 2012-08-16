require 'edge_cast/error/client_error'

module EdgeCast
  # Raised when EdgeCast returns the HTTP status code 400
  class Error::BadRequest < EdgeCast::Error::ClientError
  end
end
