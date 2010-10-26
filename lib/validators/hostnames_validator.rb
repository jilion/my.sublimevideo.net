class HostnamesValidator < ActiveModel::EachValidator
  
  def validate_each(record, attribute, hostnames)
    if hostnames.present? && !valid_hostnames?(hostnames)
      record.errors.add(attribute, I18n.t('errors.messages.invalid'), :default => options[:message])
    end
  end
  
private
  
  def valid_hostnames?(hostnames)
    hostnames.split(',').select { |h| h.present? }.each do |hostname|
      hostname.strip!
      hostname = "http://#{hostname}" unless hostname =~ %r(^\w+://.*$)
      URI.parse(hostname).host
    end
    true
  rescue
    false
  end
  
end