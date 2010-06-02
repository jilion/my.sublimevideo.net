module InvoicesHelper
  
  def cents_to_dollars(number, options = {})
    number = number/100
    number_to_currency(number, :precision => 2)
  end
  
end
