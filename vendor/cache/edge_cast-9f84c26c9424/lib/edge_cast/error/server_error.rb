require 'edge_cast/error'

module EdgeCast
  # Raised when EdgeCast returns a 5xx HTTP status code
  class Error::ServerError < EdgeCast::Error
  end
end
