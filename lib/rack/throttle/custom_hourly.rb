module Rack
  module Throttle
    class CustomHourly < Hourly

      def client_identifier(request)
        Rails.logger.debug request.headers
        if request.params["auth_token"]
          request.params["auth_token"]
        elsif request.headers["Authorization"]
          Rails.logger.debug 'request.headers["Authorization"]: ' + request.headers["Authorization"]
          request.headers["Authorization"]
        else
          request.ip.to_s
        end
      end

    end
  end
end
