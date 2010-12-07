class InvoiceMailer < SublimeVideoMailer
  helper InvoicesHelper
  
  def invoice_completed(invoice)
    @invoice = invoice
    pdf = PDFKit.new(InvoicesController.new.render_to_string(:action => 'show', :locals => { :invoice => @invoice }))
    # pdf.stylesheets << "#{Rails.root}/public/stylesheets/invoice.css"
    attachments["invoice_#{@invoice.ended_at.month}_#{@invoice.ended_at.year}.pdf"] = pdf.to_pdf
    mail(:to => "#{@invoice.user.full_name} <#{@invoice.user.email}>", :subject => "#{l(@invoice.ended_at, :format => :month_year)} invoice is ready to be charged.")
  end
  
  def charging_failed(invoice)
    @invoice = invoice
    mail(:to => "#{@invoice.user.full_name} <#{@invoice.user.email}>", :subject => "#{l(@invoice.ended_at, :format => :month_year)} invoice charging has failed.")
  end
  
end