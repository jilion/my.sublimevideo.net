class HostnameValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, hostname)
    if hostname.present?
      if Hostname.wildcard?(hostname)
        record.errors.add(attribute, :wildcard, :default => options[:message])
      elsif !Hostname.valid?(hostname)
        record.errors.add(attribute, :invalid, :default => options[:message])
      end
    end
  end

end
