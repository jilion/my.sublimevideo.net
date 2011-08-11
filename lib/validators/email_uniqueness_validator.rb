class EmailUniquenessValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, email)
    if email.present? && User.without_state(:archived).where(:email => email.downcase, :id.not_eq => record.id).exists?
      record.errors.add(attribute, :taken)
    end
  end

end