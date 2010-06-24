class InvoiceMailer < SublimeVideoMailer
  
  def invoice_calculated(invoice)
    @invoice = invoice
    mail(:to => "#{invoice.user.full_name} <#{invoice.user.email}>", :subject => "Invoice ready to be charged")
  end
  
end