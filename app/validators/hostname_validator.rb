require 'active_model'
require 'hostname_handler'

class HostnameValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, hostname)
    if hostname.present? and error = HostnameHandler.detect_error(record, hostname, :wildcard, :main_invalid)
      record.errors.add(attribute, error, default: options[:message])
    end
  end

end
