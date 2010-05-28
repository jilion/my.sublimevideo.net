require 'digest/md5'

module Exceptional
  class RackExceptionData < ExceptionData
    def initialize(exception, environment, request)
      super(exception)                  
      @environment = environment
      @request = request
    end

    def framework
      "rack"
    end

    def extra_stuff
      return {} if @request.nil?
      {
        'request' => {
          'url' => "#{@request.url}",                       
          'parameters' => @request.params,
          'request_method' => @request.request_method.to_s,
          'remote_ip' => @request.ip,
          'headers' => extract_http_headers(@environment),
          'session' => self.class.sanitize_session(@request)
        }
      }
    end
  end
end