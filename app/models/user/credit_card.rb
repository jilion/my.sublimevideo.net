# == Schema Information
#
# Table name: users
#
#  cc_type                               :string(255)
#  cc_last_digits                        :integer
#  cc_expired_on                         :date
#  cc_updated_at                         :datetime
#

module User::CreditCard
  
  attr_accessor :cc_number, :cc_first_name, :cc_last_name, :cc_verification_value
  
  # ===================================
  # = User instance methods extension =
  # ===================================
  
  def credit_card?
    cc_type.present? && cc_last_digits.present?
  end
  alias :cc? :credit_card?
  
  # validates
  def validates_credit_card
    if credit_card_attributes_present?
      # TODO
      # p credit_card.valid?
    end
  end
  
  # before_save
  def store_credit_card
    if credit_card_attributes_present?
      self.cc_last_digits = credit_card.last_digits
      self.cc_updated_at  = Time.now.utc
    end
  end
  
private
  
  def credit_card_attributes_present?
    [cc_number, cc_first_name, cc_last_name, cc_verification_value].any?(&:present?)
  end
  
  def credit_card
    @credit_card ||= ActiveMerchant::Billing::CreditCard.new(
      :type               => cc_type,
      :number             => cc_number,
      :month              => cc_expired_on.month,
      :year               => cc_expired_on.year,
      :first_name         => cc_first_name,
      :last_name          => cc_last_name,
      :verification_value => cc_verification_value
    )
  end
  
end
