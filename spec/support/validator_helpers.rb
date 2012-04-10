module RSpec
  module Support

    class Enterprise
      extend ActiveModel::Naming

      attr_accessor :hostname, :extra_hostnames, :dev_hostnames
      attr_reader   :errors

      def initialize(attributes = {})
        @errors = ActiveModel::Errors.new(self)
        attributes.each { |a, v| send("#{a}=", v) }
      end
    end

  end
end
