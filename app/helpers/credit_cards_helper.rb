module CreditCardsHelper
  
  def reset_credit_card_attributes
    unless @user.credit_card_attributes_present?
      @user.cc_type      = nil
      @user.cc_expire_on = nil
    end
  end
  
end