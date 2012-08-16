require 'faraday'
require 'edge_cast/error/bad_gateway'
require 'edge_cast/error/internal_server_error'
require 'edge_cast/error/service_unavailable'

module EdgeCast
  module Response
    class RaiseServerError < Faraday::Response::Middleware
      Faraday.register_middleware :response, :server_error => lambda { RaiseServerError }

      def on_complete(env)
        case env[:status].to_i
        when 500
          raise EdgeCast::Error::InternalServerError.new("Something is technically wrong.", env[:response_headers])
        end
      end

    end
  end
end
