module BillingsHelper

  def billing_address_missing_fields(user)
    fields = []
    user.billing_address_missing_fields.each do |field|
      fields << field.sub(/billing_/, '').sub(/address_1/, 'street').sub('_', ' ')
    end
    fields
  end

end
