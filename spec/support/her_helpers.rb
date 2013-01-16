require 'her'
require 'active_support/core_ext'
require_dependency 'api/response_parser'

module HerHelpers
  def stub_api_for(klass)
    api = Her::API.new
    klass.uses_api(api)
    api.setup url: "http://sublimevideo.dev/api" do |connection|
      connection.use Api::ResponseParser
      connection.adapter(:test) { |s| yield(s) }
    end
  end
end

RSpec.configuration.include(HerHelpers)
