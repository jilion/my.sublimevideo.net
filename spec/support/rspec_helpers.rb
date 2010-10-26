# http://rhnh.net/2010/10/06/transactional-before-all-with-rspec-and-datamapper
module RSpec
  module Support
    module RSpecExtensions
      module Set

        module ClassMethods
          # Generates a method whose return value is memoized
          # in before(:all). Great for DB setup when combined with
          # transactional before alls.
          def set(name, &block)
            define_method(name) do
              __memoized[name] ||= instance_eval(&block)
            end
            before(:all) { __send__(name) }
            before(:each) do
              __send__(name).tap do |obj|
                obj.reload if obj.respond_to?(:reload)
              end
            end
          end
        end

        module InstanceMethods
          def __memoized # :nodoc:
            @__memoized ||= {}
          end
        end

        def self.included(mod) # :nodoc:
          mod.extend ClassMethods
          mod.__send__ :include, InstanceMethods
        end

      end
    end
  end
end

# RSpec.configuration.include(Spec::Support::RSpecExtensions::Set)