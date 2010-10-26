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
      
    end
  end
end

RSpec.configuration.include(Spec::Support::VersioningHelpers)