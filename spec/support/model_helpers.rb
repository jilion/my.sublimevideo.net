module Spec
  module Support
    module ModelsHelpers

      def nil_cc_attributes
        {
          :cc_type               => nil,
          :cc_number             => nil,
          :cc_expire_on          => nil,
          :cc_full_name          => nil,
          :cc_verification_value => nil
        }
      end

      def valid_cc_attributes
        {
          :cc_type               => 'visa',
          :cc_number             => '4111111111111111',
          :cc_expire_on          => 1.year.from_now.to_date,
          :cc_full_name          => 'John Doe Huber',
          :cc_verification_value => '111'
        }
      end

      def valid_cc_3ds_attributes
        {
          :cc_type               => 'visa',
          :cc_number             => '4000000000000002',
          :cc_expire_on          => 1.year.from_now.to_date,
          :cc_full_name          => 'John Doe Huber',
          :cc_verification_value => '111'
        }
      end

      def invalid_cc_attributes
        {
          :cc_type               => 'visa',
          :cc_number             => '4111113333333333',
          :cc_expire_on          => 1.year.from_now.to_date,
          :cc_full_name          => 'John',
          :cc_verification_value => '111'
        }
      end

      def uncertain_cc_attributes
        {
          :cc_type               => 'visa',
          :cc_number             => '4111116666666666',
          :cc_expire_on          => 1.year.from_now.to_date,
          :cc_full_name          => 'John',
          :cc_verification_value => '111'
        }
      end

    end
  end
end

RSpec.configuration.include(Spec::Support::ModelsHelpers)
