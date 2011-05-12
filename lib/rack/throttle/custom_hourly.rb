module Rack
  module Throttle
    
    # The overidden #client_identifier is never called, WTF!?
    class CustomHourly < Rack::Throttle::Hourly

      protected

      def client_identifier(request)
        Rails.logger.debug request.headers
        if request.params["auth_token"]
          Rails.logger.debug 'request.headers["Authorization"]: ' + ActiveSupport::Base64.encode64("#{request.params["auth_token"]}:X")
          ActiveSupport::Base64.encode64("#{request.params["auth_token"]}:X")
        elsif request.headers["HTTP_AUTHORIZATION"]
          Rails.logger.debug 'request.headers["Authorization"]: ' + request.headers["HTTP_AUTHORIZATION"].sub('Basic ', '')
          request.headers["HTTP_AUTHORIZATION"].sub('Basic ', '')
        else
          request.ip.to_s
        end
      end

    end
  end
end
