class TransactionMailer < SublimeVideoMailer
  default :from => "SublimeVideo <billing@sublimevideo.net>"
  helper :application, :invoices

  def charging_succeeded(transaction)
    @transaction = transaction
    mail(
      :to => "\"#{@transaction.user.full_name}\" <#{@transaction.user.email}>",
      :subject => "Payment approved"
    )
  end

  def charging_failed(transaction)
    @transaction = transaction
    mail(
      :to => "\"#{@transaction.user.full_name}\" <#{@transaction.user.email}>",
      :subject => "Problem processing your payment"
    )
  end

end
