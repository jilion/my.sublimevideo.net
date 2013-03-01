class ExtraHostnamesValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, hostnames)
    if hostnames.present? and error = HostnameHandler.detect_error(record, hostnames, :wildcard, :extra_invalid, :duplicate, :include_hostname)
      record.errors.add(attribute, error, default: options[:message])
    end
  end

end
