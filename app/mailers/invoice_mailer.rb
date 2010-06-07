class InvoiceMailer < ActionMailer::Base
  default :from => "no-response@sublimevideo.net"
  
  def invoice_calculated(invoice)
    @invoice = invoice
    mail(:to => "#{invoice.user.full_name} <#{invoice.user.email}>", :subject => "Invoice ready to be charged")
  end
  
end