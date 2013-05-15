module Spec
  module Support
    module VersioningHelpers

      def with_versioning
        was_enabled = PaperTrail.enabled?
        PaperTrail.enabled = true
        begin
          yield
        ensure
          PaperTrail.enabled = was_enabled
        end
      end

      def without_versioning
        was_enabled = PaperTrail.enabled?
        PaperTrail.enabled = false
        begin
          yield
        ensure
          PaperTrail.enabled = was_enabled
        end
      end

    end
  end
end

RSpec.configure do |config|
  config.include Spec::Support::VersioningHelpers
end
