module Spec
  module Support
    module FixturesHelpers

      def fixture_file(path, mode = 'r')
        File.new(Rails.root.join('spec/fixtures', path), mode)
      end

    end
  end
end

RSpec.configuration.include(Spec::Support::FixturesHelpers)
