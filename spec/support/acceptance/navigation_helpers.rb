module Spec
  module Support
    module Acceptance
      module NavigationHelpers
        
        def homepage
          "/"
        end
        
      end
    end
  end
end

RSpec.configuration.include(Spec::Support::Acceptance::NavigationHelpers)