module CreditCardsHelper

  def reset_credit_card_attributes(user)
    unless user.any_cc_attrs?
      user.cc_type      = nil
      user.cc_expire_on = nil
    end
  end

end
