require 'base64'

module User::CreditCard

  attr_accessor :cc_update, :cc_full_name, :cc_first_name, :cc_last_name, :cc_number, :cc_verification_value, :d3d_html

  # ================================
  # = User class methods extension =
  # ================================

  # Recurring task
  def self.delay_send_credit_card_expiration(interval = 1.week)
    unless Delayed::Job.already_delayed?('%User::CreditCard%send_credit_card_expiration%')
      delay(:run_at => interval.from_now).send_credit_card_expiration
    end
  end

  def self.send_credit_card_expiration
    delay_send_credit_card_expiration
    User.where(:cc_expire_on => Time.now.utc.end_of_month.to_date).each do |user|
      CreditCardMailer.will_expire(user).deliver!
    end
  end

  # ===================================
  # = User instance methods extension =
  # ===================================

  def credit_card?
    cc_type.present? && cc_last_digits.present?
  end
  alias :cc? :credit_card?

  def credit_card_expire_this_month?
    cc_expire_on == Time.now.utc.end_of_month.to_date
  end
  alias :cc_expire_this_month? :credit_card_expire_this_month?

  def credit_card_expired?
    cc_expire_on? && cc_expire_on < Time.now.utc.to_date
  end
  alias :cc_expired? :credit_card_expired?

  def cc_full_name=(attribute)
    @cc_full_name = attribute
    if attribute.present?
      names = attribute.split(" ")
      @cc_first_name = names.first
      @cc_last_name  = names.size > 1 ? names.drop(1).join(" ") : "-"
    end
  end

  def cc_expire_on=(attribute)
    write_attribute(:cc_expire_on, attribute.respond_to?(:end_of_month) ? attribute.end_of_month.to_date : attribute)
  end

  def credit_card_attributes_present?
    [cc_update, cc_number, cc_first_name, cc_last_name, cc_verification_value].any?(&:present?)
  end

  # validates
  def validates_credit_card_attributes
    if credit_card_attributes_present?
      unless credit_card.valid?
        if cc_first_name.blank? || cc_last_name.blank?
          self.errors.add(:cc_full_name, :blank)
        end
        # I18n Warning: credit_card errors are not localized
        credit_card.errors.each do |attribute, errors|
          attribute = case attribute
          when 'month', 'year'
            errors.each do |error|
              self.errors.add(:cc_expire_on, error)
            end
          when 'number'
            self.errors.add(:cc_number, :invalid)
          when 'first_name', 'last_name'
            # do nothing
          else
            errors.each do |error|
              self.errors.add(:"cc_#{attribute}", error)
            end
          end
        end
      end
    end
  end

  # before_save
  def keep_some_credit_card_info
    if credit_card_attributes_present?
      self.cc_type        = credit_card.type
      self.cc_last_digits = credit_card.last_digits
      self.cc_updated_at  = Time.now.utc
    end
  end

  def reset_credit_card_info
    self.cc_type        = nil
    self.cc_last_digits = nil
    self.cc_expire_on   = nil
    self.cc_updated_at  = nil
  end

  # Called from CreditCardsController#update
  def check_credit_card(options={})
    if self.valid?
      options = options.merge({
        store: cc_alias,
        email: email,
        billing_address: { zip: postal_code, country: country },
        d3d: true,
        paramplus: "USER_ID=#{self.id}&CC_CHECK=TRUE"
      })
      authorize = Ogone.authorize(100, credit_card, options)

      process_cc_authorization_response(authorize.params, authorize.authorization)
    else
      nil
    end
  end

  # Called from User::CreditCard#check_credit_card and from TransactionsController#callback
  def process_cc_authorization_response(authorize_params, authorize_authorization)
    response = ""
    case authorize_params["STATUS"]
    when "5" # Authorized
      response = "authorized"
      void_authorization(authorize_authorization)
      self.save

    when "46" # Waiting for identification (3-D Secure)
              # We return the HTML to render. This HTML will redirect the user to the 3-D Secure form.
      response = "d3d"
      @d3d_html = Base64.decode64(authorize_params["HTML_ANSWER"])
      self.save

    when "0" # Credit card information invalid or incomplete
      response = "invalid"
      self.errors.add(:base, I18n.t("credit_card.errors.#{response}"))
      reset_credit_card_info

    when "2" # Authorization refused
      response = "refused"
      self.errors.add(:base, I18n.t("credit_card.errors.#{response}"))
      reset_credit_card_info

    when "51" # Authorization waiting (authorization will be processed offline), should never receive this status
      response = "waiting"
      self.save

    when "52" # Authorization not known
      response = "unknown"
      Notify.send("Credit card authorization for user ##{self.id} (PAYID: #{authorize_params["PAYID"]}) has an uncertain state, please investigate quickly!")
      self.save
    end

    response
  end

  def credit_card
    if credit_card_attributes_present?
      @credit_card ||= ActiveMerchant::Billing::CreditCard.new(
        :type               => cc_type,
        :number             => cc_number,
        :month              => cc_expire_on.try(:month),
        :year               => cc_expire_on.try(:year),
        :first_name         => cc_first_name,
        :last_name          => cc_last_name,
        :verification_value => cc_verification_value
      )
    else
      nil
    end
  end

private

  # Called from User::CreditCard#process_cc_authorization_response and TransactionsController#callback
  def void_authorization(authorization)
    void = Ogone.void(authorization)
    Notify.send("Credit card void for user #{self.id} failed: #{void.message}") unless void.success?
  end

end

User.send :include, User::CreditCard

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
