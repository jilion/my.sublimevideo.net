require 'base64'
require_dependency 'ogone'
require_dependency 'notify'

module UserModules::CreditCard
  extend ActiveSupport::Concern

  included do

    attr_accessor :cc_register, :cc_brand, :cc_full_name, :cc_number, :cc_expiration_year, :cc_expiration_month, :cc_verification_value
    attr_accessor :i18n_notice_and_alert, :d3d_html

    # validate
    def validates_credit_card_attributes
      return if cc_number.blank? # don't try to validate if cc_number is not present at all
      return if credit_card(true).valid?

      self.errors.add(:cc_full_name, :blank) unless credit_card.name?

      # I18n Warning: credit_card errors are not localized
      credit_card.errors.reject { |k,v| v.empty? }.each do |attribute, errors|
        attribute = case attribute
        when 'month', 'first_name', 'last_name'
          # do nothing
        when 'year'
          self.errors.add(:cc_expiration_year, credit_card.errors.on(:year))
        when 'type'
          self.errors.add(:cc_brand, :invalid)
        when 'number'
          self.errors.add(:cc_number, :invalid)
        else
          errors.each do |error|
            self.errors.add(:"cc_#{attribute}", error)
          end
        end
      end
    end

    def credit_card(force_refresh = false)
      reset_credit_card if force_refresh

      @credit_card ||= ActiveMerchant::Billing::CreditCard.new(
                        type:               cc_brand,
                        number:             cc_number,
                        month:              cc_expiration_month,
                        year:               cc_expiration_year,
                        first_name:         @cc_first_name,
                        last_name:          @cc_last_name,
                        verification_value: cc_verification_value)
    end

    def reset_credit_card
      @credit_card = nil
    end

    def cc_full_name=(attribute)
      @cc_full_name = attribute
      if attribute.present?
        names = attribute.split(" ")
        @cc_first_name = names.first
        @cc_last_name  = names.size > 1 ? names.drop(1).join(" ") : "-"
      end
    end

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

    # before_save if credit_card(true).valid?
    def prepare_pending_credit_card
      self.cc_register = true
      self.pending_cc_type        = credit_card.type
      self.pending_cc_last_digits = credit_card.last_digits
      self.pending_cc_expire_on   = Time.utc(credit_card.year, credit_card.month).end_of_month.to_date
      self.pending_cc_updated_at  = Time.now.utc

      reset_credit_card_attributes
    end

    def reset_credit_card_attributes
      %w[brand number expiration_month expiration_year full_name verification_value].each do |att|
        self.send("cc_#{att}=", nil)
      end
    end

    def reset_last_failed_cc_authorize_fields
      %w[at status error].each do |att|
        self.send("last_failed_cc_authorize_#{att}=", nil)
      end
    end

    # Be careful with this! Should be only used in dev and for special support-requested-credit-card-deletion purposes
    def reset_credit_card_info
      %w[type last_digits expire_on updated_at].each do |att|
        self.send("cc_#{att}=", nil)
        self.send("pending_cc_#{att}=", nil)
      end
      reset_credit_card

      self.save_skip_pwd
    end

    # We need the '_will_change!' calls since this methods is called in an after_save callback...
    def apply_pending_credit_card_info
      %w[type last_digits expire_on updated_at].each do |att|
        self.send("cc_#{att}=", self.send("pending_cc_#{att}"))
        self.send("pending_cc_#{att}=", nil)
        self.send("cc_#{att}_will_change!")
        self.send("pending_cc_#{att}_will_change!")
      end
      reset_last_failed_cc_authorize_fields

      self.save_skip_pwd
    end

    # Called from User#after_save if cc_register
    def register_credit_card_on_file(options = {})
      @i18n_notice_and_alert = nil

      options = options.merge({
        store: cc_alias,
        email: email,
        billing_address: { address1: billing_address_1, zip: billing_postal_code, city: billing_city, country: billing_country },
        d3d: true,
        paramplus: "CHECK_CC_USER_ID=#{self.id}"
      })

      authorization = begin
        Ogone.authorize(100, credit_card, options)
      rescue => ex
        Notify.send("Authorization failed: #{ex.message}", exception: ex)
        puts;puts ex.inspect;puts ex.backtrace;puts
        @i18n_notice_and_alert = { alert: "Credit card could not be verified, we have been notified." }
        nil
      end

      self.cc_register = false
      process_credit_card_authorization_response(authorization.params) if authorization
    end

    # Called from UserModules::CreditCard#register_credit_card_on_file and from TransactionsController#callback
    def process_credit_card_authorization_response(authorization_params)
      @d3d_html = nil
      reset_credit_card

      case authorization_params["STATUS"]
      # Waiting for identification (3-D Secure)
      # We return the HTML to render. This HTML will redirect the user to the 3-D Secure form.
      when "46"
        @d3d_html = Base64.decode64(authorization_params["HTML_ANSWER"])

      # STATUS == 5, Authorized:
      #   The authorization has been accepted.
      #   An authorization code is available in the field "ACCEPTANCE".
      when "5"
        void_authorization([authorization_params["PAYID"], 'RES'].join(';'))
        apply_pending_credit_card_info

      # STATUS == 51, Authorization waiting:
      #   The authorization will be processed offline.
      #   This is the standard response if the merchant has chosen offline processing in his account configuration
      when "51"
        @i18n_notice_and_alert = { notice: I18n.t("credit_card.errors.waiting") }

      # STATUS == 0, Invalid or incomplete:
      #   At least one of the payment data fields is invalid or missing.
      #   The NC ERROR  and NC ERRORPLUS  fields contains an explanation of the error
      #   (list available at https://secure.ogone.com/ncol/paymentinfos1.asp).
      #   After correcting the error, the customer can retry the authorization process.
      when "0"
        @i18n_notice_and_alert = { alert: I18n.t("credit_card.errors.invalid") }

      # STATUS == 2, Authorization refused:
      #   The authorization has been declined by the financial institution.
      #   The customer can retry the authorization process after selecting a different payment method (or card brand).
      when "2"
        @i18n_notice_and_alert = { alert: I18n.t("credit_card.errors.refused") }

      # STATUS == 52, Authorization not known:
      #   A technical problem arose during the authorization/ payment process, giving an unpredictable result.
      #   The merchant can contact the acquirer helpdesk to know the exact status of the payment or can wait until we have updated the status in our system.
      #   The customer should not retry the authorization process since the authorization/payment might already have been accepted.
      when "52"
        @i18n_notice_and_alert = { alert: I18n.t("credit_card.errors.unknown") }
        Notify.send("Credit card authorization for user ##{self.id} (PAYID: #{authorization_params["PAYID"]}) has an uncertain state, please investigate quickly!")

      else
        @i18n_notice_and_alert = { alert: I18n.t("credit_card.errors.unknown") }
        Notify.send("Credit card authorization unknown status: #{authorization_params["STATUS"]}")
      end

      unless authorization_params["STATUS"] == "5"
        set_last_failed_cc_authorize_fields_from_params(authorization_params)
      end
    end

    def set_last_failed_cc_authorize_fields_from_params(authorization_params)
      self.last_failed_cc_authorize_at     = Time.now.utc
      self.last_failed_cc_authorize_status = authorization_params["STATUS"].to_i
      self.last_failed_cc_authorize_error  = authorization_params["NCERRORPLUS"]

      self.save_skip_pwd
    end

  private

    # Called from UserModules::CreditCard#process_credit_card_authorization_response and TransactionsController#callback
    def void_authorization(authorization)
      void = Ogone.void(authorization)

      unless void.success?
        Notify.send("SUPER WARNING! Credit card authorization void for user #{self.id} failed: #{void.message}")
      end
    end

  end

  module ClassMethods

    def send_credit_card_expiration
      User.paying.where(cc_expire_on: Time.now.utc.end_of_month.to_date).each do |user|
        BillingMailer.credit_card_will_expire(user).deliver!
      end
    end

  end

end
