class HostnamesValidator < ActiveModel::EachValidator
  
  def validate_each(record, attribute, value)
    if value.present? && !hostnames_parseable?(value)
      record.errors.add(attribute, I18n.t('errors.messages.invalid'), :default => options[:message])
    end
  end
  
private
  
  def hostnames_parseable?(hostnames)
    hostnames.split(',').select { |h| h.present? }.each do |host|
      host.strip!
      host = "http://#{host}" unless host =~ %r(^\w+://.*$)
      URI.parse(host).host
    end
    true
  rescue
    false
  end
  
end