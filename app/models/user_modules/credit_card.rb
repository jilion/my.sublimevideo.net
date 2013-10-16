require 'base64'

module UserModules::CreditCard
  extend ActiveSupport::Concern

  BRANDS = %w[visa master american_express]
  CC_FIELDS = %w[type last_digits expire_on updated_at]

  included do

    attr_accessor :cc_register, :cc_brand, :cc_full_name, :cc_number, :cc_expiration_year, :cc_expiration_month, :cc_verification_value
    attr_accessor :i18n_notice_and_alert, :d3d_html

    # validate
    def validates_credit_card_attributes
      return if cc_number.blank? # don't try to validate if cc_number is not present at all
      return if credit_card(true).valid?

      self.errors.add(:cc_full_name, :blank) unless credit_card.name?

      # I18n Warning: credit_card errors are not localized
      credit_card.errors.reject { |k, v| v.empty? }.each do |attribute, errors|
        _custom_errors_handling(attribute, errors)
      end
    end

    def credit_card(force_refresh = false)
      reset_credit_card if force_refresh

      @credit_card ||= ActiveMerchant::Billing::CreditCard.new(
                        brand:              cc_brand,
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
        names = attribute.split(' ')
        @cc_first_name = names.first
        @cc_last_name  = names.size > 1 ? names.drop(1).join(' ') : '-'
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
      self.pending_cc_type        = credit_card.brand
      self.pending_cc_last_digits = credit_card.last_digits
      self.pending_cc_expire_on   = Time.utc(credit_card.year, credit_card.month).end_of_month.to_date
      self.pending_cc_updated_at  = Time.now.utc

      _reset_credit_card_attributes
    end

    # Be careful with this! Should be only used in dev and for special support-requested-credit-card-deletion purposes
    def reset_credit_card_info
      CC_FIELDS.each do |att|
        self.send("cc_#{att}=", nil)
        self.send("pending_cc_#{att}=", nil)
      end
      reset_credit_card

      save!
    end

    # Called from User#after_save if cc_register
    def register_credit_card_on_file(options = {})
      @i18n_notice_and_alert = nil

      options = options.merge({
        billing_id: cc_alias,
        email: email,
        billing_address: { address1: billing_address_1, zip: billing_postal_code, city: billing_city, country: billing_country },
        d3d: true,
        paramplus: "CHECK_CC_USER_ID=#{self.id}"
      })

      authorization = OgoneWrapper.store(credit_card, options)

      self.cc_register = false
      process_credit_card_authorization_response(authorization.params)
    end

    # Called from UserModules::CreditCard#register_credit_card_on_file and from TransactionsController#callback
    def process_credit_card_authorization_response(auth)
      @d3d_html = nil
      reset_credit_card
      _handle_authorization_response(auth['STATUS'], auth)
    end

    private

    def _handle_known_authorization_response(status, authorization)
      send("_handle_auth_#{OgoneWrapper.status[status]}", authorization)
      _increment_librato(OgoneWrapper.status[status], authorization['BRAND'].gsub(/\s/, '_'))
      _set_last_failed_cc_authorize_fields!(authorization) unless OgoneWrapper.status[status] == :authorized
    end

    def _handle_unknown_authorization_response(status, authorization)
      _set_notice('unknown', :alert)
      Notifier.send("Credit card authorization unknown status: #{status}")
    end

    def _handle_authorization_response(status, authorization)
      if OgoneWrapper.status.keys.include?(status)
        _handle_known_authorization_response(status, authorization)
      else
        _handle_unknown_authorization_response(status, authorization)
      end
    end

    def _custom_errors_handling(attribute, errors)
      case attribute
      when 'month', 'first_name', 'last_name'
        # do nothing
      when 'year'
        self.errors.add(:cc_expiration_year, credit_card.errors.on(:year))
      when 'brand', 'number'
        self.errors.add(:"cc_#{attribute}", :invalid)
      else
        errors.each { |error| self.errors.add(:"cc_#{attribute}", error) }
      end
    end

    # Waiting for identification (3-D Secure)
    # We return the HTML to render. This HTML will redirect the user to the 3-D Secure form.
    def _handle_auth_waiting_3d_secure(auth)
      @d3d_html = Base64.decode64(auth['HTML_ANSWER'])
    end

    # STATUS == 5, Authorized:
    #   The authorization has been accepted.
    #   An authorization code is available in the field "ACCEPTANCE".
    def _handle_auth_authorized(auth)
      OgoneWrapper.void([auth['PAYID'], 'RES'].join(';'))
      _save_credit_card!
    end

    # STATUS == 51, Authorization waiting:
    #   The authorization will be processed offline.
    #   This is the standard response if the merchant has chosen offline processing in his account configuration
    def _handle_auth_waiting(auth)
      _set_notice('waiting')
    end

    # STATUS == 0, Invalid or incomplete:
    #   At least one of the payment data fields is invalid or missing.
    #   The NC ERROR  and NC ERRORPLUS  fields contains an explanation of the error
    #   (list available at https://secure.ogone.com/ncol/paymentinfos1.asp).
    #   After correcting the error, the customer can retry the authorization process.
    def _handle_auth_invalid(auth)
      _set_notice('invalid', :alert)
    end

    # STATUS == 2, Authorization refused:
    #   The authorization has been declined by the financial institution.
    #   The customer can retry the authorization process after selecting a different payment method (or card brand).
    def _handle_auth_refused(auth)
      _set_notice('refused', :alert)
    end

    # STATUS == 1, Authorization canceled by client:
    #   The authorization has been canceled by the client (probably because the client failed to authenticate).
    #   The customer can retry the authorization process.
    def _handle_auth_canceled(auth)
      _set_notice('canceled', :alert)
    end

    # STATUS == 52, Authorization not known:
    #   A technical problem arose during the authorization/ payment process, giving an unpredictable result.
    #   The merchant can contact the acquirer helpdesk to know the exact status of the payment or can wait until we have updated the status in our system.
    #   The customer should not retry the authorization process since the authorization/payment might already have been accepted.
    def _handle_auth_uncertain(auth)
      _set_notice('unknown', :alert)
      Notifier.send("Credit card authorization for user ##{self.id} (PAYID: #{auth["PAYID"]}) has an uncertain state, please investigate quickly!")
    end

    def _set_last_failed_cc_authorize_fields!(auth)
      self.last_failed_cc_authorize_at     = Time.now.utc
      self.last_failed_cc_authorize_status = auth['STATUS'].to_i
      self.last_failed_cc_authorize_error  = auth['NCERRORPLUS']

      save!
    end

    # We need the '_will_change!' calls since this methods is called in an after_save callback...
    def _apply_pending_credit_card_info
      CC_FIELDS.each do |att|
        self.send("cc_#{att}=", self.send("pending_cc_#{att}"))
        self.send("pending_cc_#{att}=", nil)
        self.send("cc_#{att}_will_change!")
        self.send("pending_cc_#{att}_will_change!")
      end
    end

    def _save_credit_card!
      _apply_pending_credit_card_info
      _reset_last_failed_cc_authorize_fields

      save!
    end

    def _reset_credit_card_attributes
      %w[brand number expiration_month expiration_year full_name verification_value].each do |att|
        self.send("cc_#{att}=", nil)
      end
    end

    def _reset_last_failed_cc_authorize_fields
      %w[at status error].each do |att|
        self.send("last_failed_cc_authorize_#{att}=", nil)
      end
    end

    def _set_notice(translation_key, key = :notice)
      @i18n_notice_and_alert = { key => I18n.t("credit_card.errors.#{translation_key}") }
    end

    def _increment_librato(event, source)
      Librato.increment "credit_cards.#{event}", source: source
    end

  end

end
