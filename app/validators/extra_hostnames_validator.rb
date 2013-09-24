require 'active_model'
require 'hostname_handler'

class ExtraHostnamesValidator < HostnameValidator

  def validate_each(record, attribute, hostnames)
    validate_hostnames(record, attribute, hostnames, :wildcard, :extra_invalid, :duplicate, :include_hostname)
  end

end
