class AdminRolesValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, roles)

    if (roles - AdminRole.roles).present?
      record.errors.add(attribute, :invalid, default: options[:message])
    elsif roles.uniq.size != roles.size
      record.errors.add(attribute, :duplicate, default: options[:message])
    end

  end

end