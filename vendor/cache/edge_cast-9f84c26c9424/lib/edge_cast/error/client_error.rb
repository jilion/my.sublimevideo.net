require 'edge_cast/error'

module EdgeCast
  # Raised when EdgeCast returns a 4xx HTTP status code
  class Error::ClientError < EdgeCast::Error
  end
end
