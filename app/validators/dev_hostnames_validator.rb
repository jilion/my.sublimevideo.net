require 'active_model'
require 'hostname_handler'

class DevHostnamesValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, hostnames)
    if hostnames.present? and error = HostnameHandler.detect_error(record, hostnames, :wildcard, :dev_invalid, :duplicate, :include_hostname)
      record.errors.add(attribute, error, default: options[:message])
    end
  end

end
