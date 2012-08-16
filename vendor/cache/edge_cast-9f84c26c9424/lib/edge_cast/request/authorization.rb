require 'faraday'

module EdgeCast
  module Request
    class Authorization < Faraday::Middleware
      Faraday.register_middleware :request, :auth => lambda { Authorization }

      def initialize(app, api_token)
        @app, @api_token = app, api_token
      end

      def call(env)
        env[:request_headers]['Authorization'] = "TOK:#{@api_token}"

        @app.call(env)
      end

    end
  end
end
