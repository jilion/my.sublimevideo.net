class TransactionMailer < SublimeVideoMailer
  helper :application, :invoices

  def charging_succeeded(transaction)
    @transaction = transaction
    mail(
      :to => "\"#{@transaction.user.full_name}\" <#{@transaction.user.email}>",
      :subject => "Charging for \"#{@transaction.description}\" has succeeded."
    )
  end

  def charging_failed(transaction)
    @transaction = transaction
    mail(
      :to => "\"#{@transaction.user.full_name}\" <#{@transaction.user.email}>",
      :subject => "Charging for \"#{@transaction.description}\" has failed."
    )
  end

end
