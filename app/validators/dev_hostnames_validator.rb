require 'active_model'
require 'hostname_handler'

class DevHostnamesValidator < HostnameValidator

  def validate_each(record, attribute, hostnames)
    validate_hostnames(record, attribute, hostnames, :wildcard, :dev_invalid, :duplicate, :include_hostname)
  end

end
