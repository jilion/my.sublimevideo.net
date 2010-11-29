class InvoiceMailer < SublimeVideoMailer
  helper InvoicesHelper
  
  def invoice_completed(invoice)
    @invoice = invoice
    mail(:to => "#{@invoice.user.full_name} <#{@invoice.user.email}>", :subject => "#{l(@invoice.ended_at, :format => :month_year)} invoice is ready to be charged.")
  end
  
  def payment_failed(invoice)
    @invoice = invoice
    mail(:to => "#{@invoice.user.full_name} <#{@invoice.user.email}>", :subject => "#{l(@invoice.ended_at, :format => :month_year)} invoice charging has failed.")
  end
  
end