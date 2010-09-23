class AliasHostnamesValidator < ActiveModel::EachValidator
  
  def validate_each(record, attribute, value)
    if value.present? 
      if Hostname.wildcard?(value)
        record.errors.add(attribute, I18n.t('sites.errors.messages.wildcard'), :default => options[:message])
      elsif !Hostname.valid?(value)
        record.errors.add(attribute, I18n.t('errors.messages.invalid'), :default => options[:message])
      elsif Hostname.duplicate?(value)
        record.errors.add(attribute, I18n.t('sites.errors.messages.duplicate'), :default => options[:message])
      elsif Hostname.include?(value, record.hostname)
        record.errors.add(attribute, I18n.t('sites.errors.messages.include_hostname'), :default => options[:message])
      end
    end
  end
  
end