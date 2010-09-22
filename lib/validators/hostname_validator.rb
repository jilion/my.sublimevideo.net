class HostnameValidator < ActiveModel::EachValidator
  
  def validate_each(record, attribute, value)
    if value.present? 
      if !Hostname.valid?(value)
        record.errors.add(attribute, I18n.t('errors.messages.invalid'), :default => options[:message])
      elsif Hostname.wildcard?(value)
        record.errors.add(attribute, I18n.t('sites.errors.messages.wildcard'), :default => options[:message])
      end
    end
  end
  
end