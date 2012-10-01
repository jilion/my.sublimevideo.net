module UsersHelper

  def credit_card_warning(user)
    user.billable? && (user.cc_expire_this_month? || user.cc_expired?)
  end

  def billing_address_incomplete(user)
    user.billable? && !user.billing_address_complete?
  end

end
