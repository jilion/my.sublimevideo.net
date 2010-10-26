class ProductionHostnameValidator < ActiveModel::EachValidator
  
  def validate_each(record, attribute, hostname)
    hostname = "http://#{hostname}"  unless hostname =~ %r(^\w+://.*$) # hostname has already been cleaned in site.rb
    unless valid_hostname?(hostname) && production_hostname?(hostname)
      record.errors.add(attribute, I18n.t('errors.messages.invalid'), :default => options[:message])
    end
  end
  
private
  
  def valid_hostname?(hostname)
    URI.parse(hostname).host
    true
  rescue
    false
  end
  
  def production_hostname?(hostname)
    URI.parse(hostname).host =~ /.*\..*/
  end
  
end