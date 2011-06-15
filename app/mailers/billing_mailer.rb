class BillingMailer < ActionMailer::Base
  default :from => "SublimeVideo Billing <billing@sublimevideo.net>"
  helper :application, :invoices

  def credit_card_will_expire(user)
    @user = user
    mail(
      :to => "\"#{@user.full_name}\" <#{@user.email}>",
      :subject => "Your credit card will expire at the end of the month"
    )
  end

  def transaction_succeeded(transaction)
    @transaction = transaction
    mail(
      :to => "\"#{@transaction.user.full_name}\" <#{@transaction.user.email}>",
      :subject => "Payment approved"
    )
  end

  def transaction_failed(transaction)
    @transaction = transaction
    mail(
      :to => "\"#{@transaction.user.full_name}\" <#{@transaction.user.email}>",
      :subject => "Problem processing your payment"
    )
  end
  
  def too_many_failed_charging_attempts(invoice)
    @invoice = invoice
    mail(
      :to => ["thibaud@jilion.com", "remy@jilion.com", "zeno@jilion.com"],
      :subject => "15 failed charging attempt for Invoice ##{@invoice.reference}"
    )
  end

end
