require 'her'
require 'active_support/core_ext'
require_dependency 'api/response_parser'
require_dependency 'api/url'

module HerHelpers
  def stub_api_for(klass)
    api = Her::API.new
    klass.uses_api(api)
    api.setup url: Api::Url.new('www').url do |connection|
      connection.use Her::Middleware::AcceptJSON
      connection.use Api::ResponseParser
      connection.use Faraday::Request::UrlEncoded
      connection.use Faraday::Adapter::NetHttp
      connection.adapter(:test) { |s| yield(s) }
    end
  end
end

RSpec.configuration.include(HerHelpers)
