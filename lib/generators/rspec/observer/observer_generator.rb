require 'generators/rspec'

module Rspec
  module Generators
    class ObserverGenerator < Base
      def create_observer_files
        template 'observer_spec.rb',
                 File.join('spec', 'models', class_path, "#{file_name}_observer_spec.rb")
      end
    end
  end
end