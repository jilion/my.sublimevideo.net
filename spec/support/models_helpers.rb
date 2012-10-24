module Spec
  module Support
    module ModelsHelpers

      def nil_cc_attributes
        {
          cc_brand:              nil,
          cc_full_name:          nil,
          cc_number:             nil,
          cc_expiration_month:   nil,
          cc_expiration_year:    nil,
          cc_verification_value: nil
        }
      end

      def valid_cc_attributes
        {
          cc_brand:              'visa',
          cc_full_name:          'John Doe Huber',
          cc_number:             '4111111111111111',
          cc_expiration_month:   1.year.from_now.month,
          cc_expiration_year:    1.year.from_now.year,
          cc_verification_value: '111'
        }
      end

      def valid_cc_attributes_visa
        valid_cc_attributes
      end

      def valid_cc_attributes_master
        {
          cc_brand:              'master',
          cc_full_name:          'Bob Doe Hicks',
          cc_number:             '5399999999999999',
          cc_expiration_month:   2.years.from_now.month,
          cc_expiration_year:    2.years.from_now.year,
          cc_verification_value: '111'
        }
      end

      def valid_cc_attributes_american_express
        {
          cc_brand:              'american_express',
          cc_full_name:          'Bob Doe Hicks',
          cc_number:             '374111111111111',
          cc_expiration_month:   3.years.from_now.month,
          cc_expiration_year:    3.years.from_now.year,
          cc_verification_value: '111'
        }
      end

      def valid_cc_d3d_attributes
        {
          cc_brand:              'visa',
          cc_full_name:          'John Doe Huber',
          cc_number:             '4000000000000002',
          cc_expiration_month:   1.year.from_now.month,
          cc_expiration_year:    1.year.from_now.year,
          cc_verification_value: '111'
        }
      end

      def invalid_cc_attributes
        {
          cc_brand:              'visa',
          cc_full_name:          'John Doe Huber',
          cc_number:             '4111113333333333',
          cc_expiration_month:   1.year.from_now.month,
          cc_expiration_year:    1.year.from_now.year,
          cc_verification_value: '111'
        }
      end

      def uncertain_cc_attributes
        {
          cc_brand:              'visa',
          cc_full_name:          'John Doe Huber',
          cc_number:             '4111116666666666',
          cc_expiration_month:   1.year.from_now.month,
          cc_expiration_year:    1.year.from_now.year,
          cc_verification_value: '111'
        }
      end

    end
  end
end

RSpec.configuration.include(Spec::Support::ModelsHelpers)
