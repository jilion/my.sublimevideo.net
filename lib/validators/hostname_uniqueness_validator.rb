class HostnameUniquenessValidator < ActiveModel::EachValidator
  
  def validate_each(record, attribute, value)
    if record.user && record.user.sites.not_archived.where(:hostname => value, :id.not_eq => record.id).exists?
      record.errors.add(attribute, I18n.t('activerecord.errors.messages.taken'), :default => options[:message])
    end
  end
  
end