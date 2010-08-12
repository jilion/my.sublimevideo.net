require 'net/http'

module Zendesk
  
  class Request
    def initialize(url, verb = :get, params = {})
      @verb   = verb.to_sym
      @url    = Zendesk.parse_url(url.to_s)
      @params = Zendesk.params_to_xml(params)
      @headers = "Net::HTTP::#{verb.to_s.camelize}".constantize.new(@url.path)
      @headers.basic_auth(Zendesk.username, Zendesk.password)
      @headers.content_type = "application/xml" if params_required?
    end
    
    def execute
      res = Net::HTTP.start(@url.host, @url.port) do |http|
        if params_required?
          http.request(@headers, @params)
        else
          http.request(@headers)
        end
      end
      Zendesk.response(res)
    end
    
    def params_required?
      [:post, :put].include?(@verb)
    end
  end
  
  class << self
    def get(url)
      Zendesk::Request.new(url, :get).execute
    end
    
    def post(url, params = {})
      Zendesk::Request.new(url, :post, params).execute
    end
    
    def put(url, params = {})
      Zendesk::Request.new(url, :put, params).execute
    end
    
    def parse_url(url)
      URI.parse("#{base_url}#{url}")
    end
    
    def params_to_xml(hash)
      hash.inject("") do |memo, h|
        key = h[0].to_s.dasherize
        memo += "<#{key}>#{h[1].is_a?(Hash) ? params_to_xml(h[1]) : h[1]}</#{key}>"
      end
    end
    
    def response(response)
      case response
      when Net::HTTPSuccess, Net::HTTPRedirection
        response
      else
        response.error!
      end
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
  
end