class InvoiceMailer < SublimeVideoMailer
  helper :application, :invoices

  def invoice_completed(invoice)
    @invoice = invoice
    mail(:to => "\"#{@invoice.user.full_name}\" <#{@invoice.user.email}>", :subject => "#{l(@invoice.created_at, :format => :month_fullyear)} invoice is ready to be charged.")
  end

  def charging_failed(invoice)
    @invoice = invoice
    mail(:to => "\"#{@invoice.user.full_name}\" <#{@invoice.user.email}>", :subject => "#{l(@invoice.created_at, :format => :month_fullyear)} invoice charging has failed.")
  end

end
