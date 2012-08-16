require 'faraday'
require 'edge_cast/error/bad_request'
require 'edge_cast/error/forbidden'
require 'edge_cast/error/method_not_allowed'
require 'edge_cast/error/not_acceptable'
require 'edge_cast/error/not_found'
require 'edge_cast/error/unauthorized'

module EdgeCast
  module Response
    class RaiseClientError < Faraday::Response::Middleware
      Faraday.register_middleware :response, :client_error => lambda { RaiseClientError }

      def on_complete(env)
        case env[:status].to_i
        when 400
          raise EdgeCast::Error::BadRequest.new(error_body(env[:body]), env[:response_headers])
        when 401
          raise EdgeCast::Error::Unauthorized.new(error_body(env[:body]), env[:response_headers])
        when 403
          raise EdgeCast::Error::Forbidden.new(error_body(env[:body]), env[:response_headers])
        when 404
          raise EdgeCast::Error::NotFound.new(error_body(env[:body]), env[:response_headers])
        when 405
          raise EdgeCast::Error::MethodNotAllowed.new(error_body(env[:body]), env[:response_headers])
        when 406
          raise EdgeCast::Error::NotAcceptable.new(error_body(env[:body]), env[:response_headers])
        end
      end

    private

      def error_body(body)
        if body.nil?
          ''
        elsif body['error']
          body['error']
        elsif body['errors']
          first = Array(body['errors']).first
          if first.kind_of?(Hash)
            first['message'].chomp
          else
            first.chomp
          end
        end
      end

    end
  end
end
