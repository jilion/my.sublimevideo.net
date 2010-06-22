# == Schema Information
#
# Table name: users
#
#  cc_type              :string(255)
#  cc_last_digits       :integer
#  cc_expire_on         :date
#  cc_updated_at        :datetime
#

module User::CreditCard
  
  attr_accessor :cc_update, :cc_full_name, :cc_first_name, :cc_last_name, :cc_number, :cc_verification_value
  
  # ===================================
  # = User instance methods extension =
  # ===================================
  
  def credit_card?
    cc_type.present? && cc_last_digits.present?
  end
  alias :cc? :credit_card?
  
  def cc_full_name=(attribute)
    @cc_full_name = attribute
    if attribute.present?
      names = attribute.split(" ")
      @cc_first_name = names.first
      @cc_last_name  = names.size > 1 ? names.drop(1).join(" ") : "-"
    end
  end
  
  def credit_card_attributes_present?
    [cc_update, cc_number, cc_first_name, cc_last_name, cc_verification_value].any?(&:present?)
  end
  
  def credit_card_name
    case cc_type
    when 'visa'
      'Visa'
    when 'master'
      'MasterCard'
    end
  end
  
  # validates
  def validates_credit_card_attributes
    if credit_card_attributes_present?
      unless credit_card.valid?
        if cc_first_name.blank? || cc_last_name.blank?
          self.errors.add(:cc_full_name, :empty)
        end
        # I18n Warning: credit_card errors are not localized
        credit_card.errors.each do |attribute,errors|
          attribute = case attribute
          when 'month', 'year'
            errors.each do |error|
              self.errors.add(:cc_expire_on, error)
            end
          when 'first_name', 'last_name'
            # do nothing
          else
            errors.each do |error|
              self.errors.add("cc_#{attribute}".to_sym, error)
            end
          end
        end
      end
    end
  end
  
  # before_save
  def store_credit_card
    if credit_card_attributes_present? && errors.empty?
      authorize = Ogone.authorize(100 + rand(500), credit_card, :currency => 'USD', :store => "sublime_#{id}")
      if authorize.success?
        void_authorization(authorize)
      else
        self.errors.add(:base, "Credit card authorization failed")
        false
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
  
private
  
  def void_authorization(authorize)
    void = Ogone.void(authorize.authorization)
    HoptoadNotifier.notify("Credit card void for user #{id} failed: #{void.message}") unless void.success?
  end
  
  def credit_card
    @credit_card ||= ActiveMerchant::Billing::CreditCard.new(
      :type               => cc_type,
      :number             => cc_number,
      :month              => cc_expire_on.month,
      :year               => cc_expire_on.year,
      :first_name         => cc_first_name,
      :last_name          => cc_last_name,
      :verification_value => cc_verification_value
    )
  end
  
end
