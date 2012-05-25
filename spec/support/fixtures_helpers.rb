module Spec
  module Support
    module FixturesHelpers

      def fixture_file(path)
        File.new(Rails.root.join('spec/fixtures', path))
      end

    end
  end
end

RSpec.configuration.include(Spec::Support::FixturesHelpers)
