require 'base64'

module User::CreditCard
  extend ActiveSupport::Memoizable

  attr_accessor :cc_update, :cc_full_name, :cc_first_name, :cc_last_name, :cc_number, :cc_verification_value

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

  def credit_card_alias
    "sublime_#{id}"
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
  
  def check_credit_card
    options = { store: credit_card_alias, flag_3ds: true } # , accept_url: '', decline_url: '', exception_url: '' }
    authorize = Ogone.authorize(100 + rand(500), credit_card, options)
    
    Rails.logger.info "authorize.params[\"STATUS\"]: #{authorize.params["STATUS"].to_i}"
    
    case authorize.params["STATUS"].to_i
    when 5 # The authorization has been accepted.
      void_authorization(authorize.authorization)
      nil
    when 46 # Waiting for identification
      html_answer = Base64.encode64(authorize.params["HTML_ANSWER"])
      Rails.logger.info "authorize.params[\"HTML_ANSWER\"]: #{authorize.params["HTML_ANSWER"].to_i}"
      
    else # Something went wrong
      Rails.logger.info "authorize.params[\"NCERROR\"]: #{authorize.params["NCERROR"]}"
      Rails.logger.info "authorize.params[\"NCERRORPLUS\"]: #{authorize.params["NCERRORPLUS"]}"
      self.errors.add(:base, "Credit card authorization failed")
      Rails.logger.info self.errors.inspect
      nil
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

  def void_authorization(authorization)
    void = Ogone.void(authorization)
    unless void.success?
      Notify.send("Credit card void for user #{user.id} failed: #{void.message}")
    end
  end

private

  def credit_card
    ActiveMerchant::Billing::CreditCard.new(
      :type               => cc_type,
      :number             => cc_number,
      :month              => cc_expire_on.try(:month),
      :year               => cc_expire_on.try(:year),
      :first_name         => cc_first_name,
      :last_name          => cc_last_name,
      :verification_value => cc_verification_value
    )
  end
  memoize :credit_card

end

User.send :include, User::CreditCard

# == Schema Information
#
# Table name: users
#
#  cc_type              :string(255)
#  cc_last_digits       :integer
#  cc_expire_on         :date
#  cc_updated_at        :datetime
#
