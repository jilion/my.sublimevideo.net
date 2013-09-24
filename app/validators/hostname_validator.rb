require 'active_model'
require 'hostname_handler'

class HostnameValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, hostname)
    validate_hostnames(record, attribute, hostname, :wildcard, :main_invalid)
  end

  private

  def validate_hostnames(*args)
    record = args.shift
    attribute = args.shift
    hostnames = args.shift
    validations = args

    if hostnames.present? and error = HostnameHandler.detect_error(record, hostnames, *validations)
      record.errors.add(attribute, error, default: options[:message])
    end
  end

end
