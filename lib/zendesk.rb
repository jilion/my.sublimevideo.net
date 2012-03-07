require 'net/http'

module Zendesk
  include Configurator

  heroku_config_file 'zendesk.yml'

  heroku_config_accessor 'ZENDESK', :base_url, :username, :api_token

  class << self

    def get(url)
      Zendesk::Request.new(url, :get).execute
    end

    def post(url, params={})
      Zendesk::Request.new(url, :post, params).execute
    end

    def put(url, params={})
      Zendesk::Request.new(url, :put, params).execute
    end

    def delete(url)
      Zendesk::Request.new(url, :delete).execute
    end

  end

  class Request
    def initialize(url, verb, params={})
      @verb    = verb.to_s
      @url     = URI.parse("#{Zendesk.base_url}#{url}")
      @params  = params
      @headers = "Net::HTTP::#{@verb.classify}".constantize.new(@url.path)
      @headers.basic_auth("#{Zendesk.username}/token", Zendesk.api_token)
    end

    def execute
      rescue_and_retry(5, Net::HTTPServerException) do
        http_response = Net::HTTP.start(@url.host, @url.port, use_ssl: true) do |http|
          if @params.present?
            @headers.content_type = "application/xml"
            http.request(@headers, @params)
          else
            http.request(@headers)
          end
        end

        Zendesk::Response.new(http_response)
      end
    end
  end

  class Response
    attr_accessor :http_response

    def initialize(http_response)
      @http_response = http_response

      case @http_response
      when Net::HTTPSuccess
        self
      else
        @http_response.error!
      end
    end

    def location
      @http_response['location']
    end

    def body
      JSON[@http_response.body]
    end
  end

end
