class ExtraHostnamesValidator < ActiveModel::EachValidator
  
  def validate_each(record, attribute, hostnames)
    if hostnames.present? 
      if Hostname.wildcard?(hostnames)
        record.errors.add(attribute, I18n.t('sites.errors.messages.wildcard'), :default => options[:message])
      elsif !Hostname.extra_valid?(hostnames)
        record.errors.add(attribute, I18n.t('errors.messages.invalid'), :default => options[:message])
      elsif Hostname.duplicate?(hostnames)
        record.errors.add(attribute, I18n.t('sites.errors.messages.duplicate'), :default => options[:message])
      elsif Hostname.include?(hostnames, record.hostname)
        record.errors.add(attribute, I18n.t('sites.errors.messages.include_hostname'), :default => options[:message])
      end
    end
  end
  
end