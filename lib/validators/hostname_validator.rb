class HostnameValidator < ActiveModel::EachValidator
  
  def validate_each(record, attribute, hostname)
    if hostname.present? 
      if Hostname.wildcard?(hostname)
        record.errors.add(attribute, I18n.t('sites.errors.messages.wildcard'), :default => options[:message])
      elsif !Hostname.valid?(hostname)
        record.errors.add(attribute, I18n.t('errors.messages.invalid'), :default => options[:message])
      end
    end
  end
  
end