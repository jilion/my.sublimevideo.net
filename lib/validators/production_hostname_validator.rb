class ProductionHostnameValidator < ActiveModel::EachValidator
  
  def validate_each(record, attribute, value)
    value = "http://#{value}" # hostname has already been cleaned in site.rb
    unless hostname_parseable?(value) && production_hostname?(value)
      record.errors.add(attribute, I18n.t('errors.messages.invalid'), :default => options[:message])
    end
  end
  
private
  
  def hostname_parseable?(hostname)
    URI.parse(hostname)
    true
  rescue
    false
  end
  
  def production_hostname?(hostname)
    URI.parse(hostname).host =~ /.*\..*/
  end
  
end