class InvoiceMailer < SublimeVideoMailer
  helper InvoicesHelper
  
  def invoice_completed(invoice)
    @invoice = invoice
    pdf = PDFKit.new(render_to_string(:controller => 'invoices', :action => 'show', :id => @invoice.reference)).to_pdf
    attachments["invoice#{@invoice.ended_at.month}_#{@invoice.ended_at.year}.pdf"] = pdf
    mail(:to => "#{@invoice.user.full_name} <#{@invoice.user.email}>", :subject => "#{l(@invoice.ended_at, :format => :month_year)} invoice is ready to be charged.")
  end
  
  def charging_failed(invoice)
    @invoice = invoice
    mail(:to => "#{@invoice.user.full_name} <#{@invoice.user.email}>", :subject => "#{l(@invoice.ended_at, :format => :month_year)} invoice charging has failed.")
  end
  
end