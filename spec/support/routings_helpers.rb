module Spec
  module Support
    module RoutingsHelpers

      def with_subdomain(subdomain, route)
        "http://#{subdomain}.sublimevideo.dev#{route.start_with?("/") ? route : "/#{route}"}"
      end

    end
  end
end

RSpec.configure do |config|
  config.include Spec::Support::RoutingsHelpers
end
