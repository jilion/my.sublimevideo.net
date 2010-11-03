class HostnameUniquenessValidator < ActiveModel::EachValidator
  
  def validate_each(record, attribute, hostname)
    if record.user && hostname.present? && record.user.sites.not_archived.where(:hostname => hostname, :id.not_eq => record.id).exists?
      record.errors.add(attribute, :taken, :default => options[:message])
    end
  end
  
end