require 'base64'

module UserModules::Billing
  extend ActiveSupport::Concern

  included do

    def sponsored?
      sites.not_archived.includes(:billable_items).where { billable_items.state == 'sponsored' }.present?
    end

    def billable?
      sites.not_archived.paying.count > 0
    end

    def trial_or_billable?
      billable? || sites.not_archived.any? { |site| site.total_billable_items_price > 0 }
    end

    def billing_address_complete?
      _billing_address_attributes.all?(&:present?)
    end

    def billing_address_missing_fields
      %w[billing_address_1 billing_postal_code billing_city billing_country].reject do |field|
        self.send(field).present?
      end
    end

    def billing_name_or_billing_email
      billing_name.presence || billing_email
    end

    def billing_address(fallback_to_name = true)
      Snail.new(
        name:        billing_name.presence || (fallback_to_name ? name : nil),
        line_1:      billing_address_1,
        line_2:      billing_address_2,
        postal_code: billing_postal_code,
        city:        billing_city,
        region:      billing_region,
        country:     billing_country.to_s
      ).to_s
    end

    private

    def _billing_address_attributes
      [billing_address_1, billing_postal_code, billing_city, billing_country]
    end

  end

end
