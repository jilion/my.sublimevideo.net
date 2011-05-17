require 'net/http'

module Zendesk

  class << self

    [:base_url, :username, :password, :api_token].each do |method_name|
      define_method(method_name) { yml[method_name] == 'heroku_env' ? ENV["ZENDESK_#{method_name.to_s.upcase}"] : yml[method_name] }
    end

    def get(url)
      Zendesk::Request.new(url, :get).execute
    end

    def post(url, params={})
      Zendesk::Request.new(url, :post, params).execute
    end

    def put(url, params={})
      Zendesk::Request.new(url, :put, params).execute
    end

    def method_missing(name)
      yml[name.to_sym]
    end

    private

    def yml
      config_path = Rails.root.join('config', 'zendesk.yml')
      @@yml_options ||= YAML::load_file(config_path)[Rails.env]
      @@yml_options.to_options
    rescue
      raise StandardError, "Zendesk config file '#{config_path}' doesn't exist."
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
        response = Net::HTTP.start(@url.host, @url.port) do |http|
          if @params.present?
            @headers.content_type = "application/xml"
            http.request(@headers, @params)
          else
            http.request(@headers)
          end
        end

        case response
        when Net::HTTPSuccess
          response
        else
          response.error!
        end
      end
    end
  end

end
