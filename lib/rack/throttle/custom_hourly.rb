module Rack
  module Throttle
    class CustomHourly < Hourly

      def client_identifier(request)
        if request.params["auth_token"]
          request.params["auth_token"]
        else
          request.ip.to_s
        end
      end

    end
  end
end
