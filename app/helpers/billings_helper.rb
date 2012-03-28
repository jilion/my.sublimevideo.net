module BillingsHelper

  def credit_card_type(cc_type)
    case cc_type
    when /visa/
      'Visa'
    when /master/
      'MasterCard'
    end
  end

end
