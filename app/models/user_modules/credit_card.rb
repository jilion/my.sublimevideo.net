require 'base64'

module UserModules::CreditCard
  extend ActiveSupport::Concern

  included do

    attr_accessor :cc_register, :cc_brand, :cc_full_name, :cc_number, :cc_expiration_year, :cc_expiration_month, :cc_verification_value
    attr_accessor :i18n_notice_and_alert, :d3d_html

    # validate :if => :any_cc_attrs?
    def validates_credit_card_attributes
      @credit_card = new_credit_card # reset the current credit card

      return if credit_card.valid?

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

    def new_credit_card
      ActiveMerchant::Billing::CreditCard.new(
        :type               => cc_brand,
        :number             => cc_number,
        :month              => cc_expiration_month,
        :year               => cc_expiration_year,
        :first_name         => @cc_first_name,
        :last_name          => @cc_last_name,
        :verification_value => cc_verification_value
      )
    end

    def credit_card
      @credit_card ||= new_credit_card
    end

    def cc_full_name=(attribute)
      @cc_full_name = attribute
      if attribute.present?
        names = attribute.split(" ")
        @cc_first_name = names.first
        @cc_last_name  = names.size > 1 ? names.drop(1).join(" ") : "-"
      end
    end

    def any_credit_card_attributes_present?
      if cc_register.to_i == 1
        [cc_brand, cc_number, cc_full_name, cc_expiration_month, cc_expiration_year, cc_verification_value].any?(&:present?)
      else
        reset_credit_card_attributes
        false
      end
    end
    alias :any_cc_attrs? :any_credit_card_attributes_present?

    def credit_card?
      [cc_type, cc_last_digits, cc_expire_on, cc_updated_at].all?(&:present?)
    end
    alias :cc? :credit_card?

    def pending_credit_card?
      [pending_cc_type, pending_cc_last_digits, pending_cc_expire_on, pending_cc_updated_at].all?(&:present?)
    end
    alias :pending_cc? :pending_credit_card?

    def credit_card_expire_this_month?
      cc_expire_on == Time.now.utc.end_of_month.to_date
    end
    alias :cc_expire_this_month? :credit_card_expire_this_month?

    def credit_card_expired?
      credit_card? && cc_expire_on < Time.now.utc.to_date
    end
    alias :cc_expired? :credit_card_expired?

    # before_save if any_cc_attrs?
    def pend_credit_card_info
      self.pending_cc_type        = credit_card.type
      self.pending_cc_last_digits = credit_card.last_digits
      self.pending_cc_expire_on   = Time.utc(credit_card.year, credit_card.month).end_of_month.to_date
      self.pending_cc_updated_at  = Time.now.utc

      reset_credit_card_attributes
    end

    def reset_credit_card_attributes
      %w[cc_brand cc_number cc_expiration_month cc_expiration_year cc_full_name cc_verification_value].each { |att| self.send("#{att}=", nil) }
    end

    # Be careful with this! Should be only used in dev and for special support-requested-credit-card-deletion purposes
    def reset_credit_card_info
      self.cc_type        = nil
      self.cc_last_digits = nil
      self.cc_expire_on   = nil
      self.cc_updated_at  = nil

      self.save
    end

    def apply_pending_credit_card_info
      self.cc_type        = pending_cc_type
      self.cc_last_digits = pending_cc_last_digits
      self.cc_expire_on   = pending_cc_expire_on
      self.cc_updated_at  = pending_cc_updated_at
      self.pending_cc_type        = nil
      self.pending_cc_last_digits = nil
      self.pending_cc_expire_on   = nil
      self.pending_cc_updated_at  = nil

      self.save
    end

    # Called from CreditCardsController#update
    def register_credit_card_on_file(options = {})
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
        @i18n_notice_and_alert = { alert: "Credit card could not be verified, we have been notified." }
        nil
      end

      process_credit_card_authorization_response(authorization.params) if authorization
    end

    # Called from UserModules::CreditCard#register_credit_card_on_file and from TransactionsController#callback
    def process_credit_card_authorization_response(authorization_params)
      @d3d_html = nil

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
        # pend_credit_card_info if any_cc_attrs? # not called with d3d callback
        apply_pending_credit_card_info # save

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
    end

  private

    # Called from UserModules::CreditCard#process_credit_card_authorization_response and TransactionsController#callback
    def void_authorization(authorization)
      void = Ogone.void(authorization)
      Notify.send("SUPER WARNING! Credit card authorization void for user #{self.id} failed: #{void.message}") unless void.success?
    end

  end

  module ClassMethods

    # Recurring task
    def delay_send_credit_card_expiration(interval = 1.week)
      unless Delayed::Job.already_delayed?('%UserModules::CreditCard%send_credit_card_expiration%')
        delay(:run_at => interval.from_now).send_credit_card_expiration
      end
    end

    def send_credit_card_expiration
      delay_send_credit_card_expiration
      User.active_and_billable.where(cc_expire_on: Time.now.utc.end_of_month.to_date).each do |user|
        BillingMailer.credit_card_will_expire(user).deliver!
      end
    end

  end

end

# == Schema Information
#
# Table name: users
#
#  cc_type              :string(255)
#  cc_last_digits       :string(255)
#  cc_expire_on         :date
#  cc_updated_at        :datetime
#  cc_alias             :string
#
