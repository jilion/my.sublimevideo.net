# == Schema Information
#
# Table name: users
#
#  cc_type                               :string(255)
#  cc_last_digits                        :integer
#  cc_expired_at                         :datetime
#  cc_updated_at                         :datetime
#


module User::CreditCard
  
  
  
  # ===================================
  # = User instance methods extension =
  # ===================================
  
  def credit_card?
    cc_type.present? && cc_last_digits.present?
  end
  alias :cc? :credit_card?
  
  
  
  
end
