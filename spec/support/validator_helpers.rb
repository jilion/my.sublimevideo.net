module Spec
  module Support
    
    class Enterprise
      extend ActiveModel::Naming
      
      attr_accessor :hostnames
      attr_reader   :errors
      
      def initialize
        @errors = ActiveModel::Errors.new(self)
      end
    end
    
  end
end