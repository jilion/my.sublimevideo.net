module InvoicesHelper
  
  def reference(invoice)
    invoice.current? ? "— —" : invoice.reference
  end
  
  def cents_to_dollars(number, options = {})
    number = number/100.0
    number_to_currency(number, :precision => 2)
  end
  
end