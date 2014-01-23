require 'base64'

module UserModules::CreditCard
  extend ActiveSupport::Concern

  BRANDS = %w[visa master american_express]
  CC_FIELDS = %w[type last_digits expire_on updated_at]

  included do

    attr_accessor :cc_register, :cc_brand, :cc_full_name, :cc_number, :cc_expiration_year, :cc_expiration_month, :cc_verification_value
    attr_accessor :i18n_notice_and_alert, :d3d_html

    def credit_card?
      [cc_type, cc_last_digits, cc_expire_on, cc_updated_at].all?(&:present?)
    end
    alias :cc? :credit_card?

    def pending_credit_card?
      [pending_cc_type, pending_cc_last_digits, pending_cc_expire_on, pending_cc_updated_at].all?(&:present?)
    end
    alias :pending_cc? :pending_credit_card?

    def credit_card_expire_this_month?
      credit_card? && cc_expire_on == Time.now.utc.end_of_month.to_date
    end
    alias :cc_expire_this_month? :credit_card_expire_this_month?

    def credit_card_expired?
      credit_card? && cc_expire_on < Time.now.utc.to_date
    end
    alias :cc_expired? :credit_card_expired?

    # Be careful with this! Should be only used in dev and for special support-requested-credit-card-deletion purposes
    def reset_credit_card_info
      CC_FIELDS.each do |att|
        self.send("cc_#{att}=", nil)
        self.send("pending_cc_#{att}=", nil)
      end

      save!
    end

  end

end
