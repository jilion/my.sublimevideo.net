class HostnameUniquenessValidator < ActiveModel::EachValidator
  
  def validate_each(record, attribute, value)
    if record.new_record? && record.user && record.user.sites.not_archived.where(:hostname => value).exists?
      record.errors.add(attribute, :taken, :default => options[:message])
    end
  end
  
end