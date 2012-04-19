# encoding: utf-8 

module LogsFileFormat
  module Voxcast
    extend RequestLogAnalyzer::FileFormat::CommonRegularExpressions

    LINE_DEFINITIONS = [
      { regexp: '(\d+|\-)',                   captures: [{ name: :cache_miss_reason, type: :integer }] },
      { regexp: '(\d+|\-)',                   captures: [{ name: :cache_status,      type: :integer }] },
      { regexp: "(#{ip_address})",            captures: [{ name: :client_ip,         type: :string }] },
      { regexp: "(#{timestamp('%Y-%m-%d')})", captures: [{ name: :log_date,          type: :timestamp }] },
      { regexp: "(#{timestamp('%Y-%m-%d')})", captures: [{ name: :date,              type: :timestamp }] },
      { regexp: '(\d{3})',                    captures: [{ name: :first_http_status, type: :integer }] },
      { regexp: '(\S+)',                      captures: [{ name: :http_method,       type: :string }] },
      { regexp: '\"(.*)\"',                   captures: [{ name: :http_request,      type: :string }] },
      { regexp: '(\d{3})',                    captures: [{ name: :http_status,       type: :integer }] },
      { regexp: '\"(.*)\"',                   captures: [{ name: :referrer,          type: :string }] },
      { regexp: '\"(.*)\"',                   captures: [{ name: :path,              type: :string }] },
      { regexp: '\"(.*)\"',                   captures: [{ name: :path_query,        type: :string }] },
      { regexp: '\"(.*)\"',                   captures: [{ name: :path_stem,         type: :string }] },
      { regexp: '(.*)',                       captures: [{ name: :rfc_1413_identity, type: :string }] },
      { regexp: '(.*)',                       captures: [{ name: :server_name,       type: :string }] },
      { regexp: '(\d+|-)',                    captures: [{ name: :request_bytes,     type: :traffic }] },
      { regexp: '(\d+|-)',                    captures: [{ name: :response_bytes,    type: :traffic }] },
      { regexp: "(#{timestamp('%H:%M:%S')})", captures: [{ name: :log_time,          type: :timestamp }] },
      { regexp: "(#{timestamp('%H:%M:%S')})", captures: [{ name: :time,              type: :timestamp }] },
      { regexp: '(\d+|-)',                    captures: [{ name: :duration,          type: :duration, unit: :musec }] },
      { regexp: '\"(.*)\"',                   captures: [{ name: :useragent,         type: :string }] },
      { regexp: '(\d+|-)',                    captures: [{ name: :user_id,           type: :string }] },
      # include " " inside () or it'll failed with old log without edge_location
      { regexp: '(.*)',                       captures: [{ name: :edge_location,     type: :string }] }
    ]

    def create(*args)
      self.new({ default: line_definition }, report_trackers)
    end

    def line_definition
      regexps, captures = [], []

      LINE_DEFINITIONS.each do |definition|
        regexps  << definition[:regexp]
        captures += definition[:captures]
      end

      RequestLogAnalyzer::LineDefinition.new(
        :default,
        regexp: Regexp.new(regexps.join('\s')),
        captures: captures,
        header: true,
        footer: true
      )
    end

    def token_from(request)
      if token = request[:path].match(/^.*(\/|t\=)([a-z0-9]{8})($|&|\.|\/)/)
        token[2]
      end
    end

    def token?(request)
      !!token_from(request)
    end

    def loader_token_from(request)
      if loader_token = request[:path].match(/^\/js\/([a-z0-9]{8})\.js.*/)
        loader_token[1]
      end
    end

    def loader_token?(request)
      !!loader_token_from(request)
    end

    def player_token_from(request)
      if player_token = request[:path].match(/^\/p(\/.*)?\/sublime\.js(\.jgz|\.gz)?\?t=([a-z0-9]{8}).*/)
        player_token[3]
      end
    end

    def player_token?(request)
      !!player_token_from(request)
    end

    def flash_token_from(request)
      if flash_token = request[:path].match(/^\/p(\/.*)?\/sublime\.swf\?t=([a-z0-9]{8}).*/)
        flash_token[2]
      end
    end

    def flash_token?(request)
      !!flash_token_from(request)
    end

    def countable_hit?(request)
      request[:cache_miss_reason] != 3
    end

    def gif_request?(request)
      request[:path_stem] == "/_.gif"
    end

    def event_is?(request, event_code='l')
      request[:path_query] =~ /[\?&]?e=#{event_code}&?/
    end

    def good_token?(request)
      request[:path_query] =~ /[\?&]t=([a-z0-9]{8})(&|$)/
    end

    def remove_timestamp(request)
      request[:path_query].gsub(/&i=[0-9]+/, '')
    end

  end
end