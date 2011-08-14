class EmailUniquenessValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, email_address)
    if email_address.present? && User.where { (state != 'archived') & (lower(email) == lower(email_address)) & (id != record.id) }.exists?
      record.errors.add(attribute, :taken)
    end
  end

end