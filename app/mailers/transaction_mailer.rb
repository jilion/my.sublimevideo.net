class TransactionMailer < SublimeVideoMailer
  helper :application, :invoices

  def charging_failed(transaction)
    @transaction = transaction
    mail(
      :to => "\"#{@transaction.user.full_name}\" <#{@transaction.user.email}>",
      :subject => "Payment problem"
    )
  end

end
