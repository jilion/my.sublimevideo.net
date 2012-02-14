class HostnameUniquenessValidator < ActiveModel::EachValidator

  def validate_each(record, attribute, hostname)
    if record.user && hostname.present? && active_site_with_same_user_and_hostname_exists?(record, hostname)
      record.errors.add(attribute, :taken, default: options[:message])
    end
  end

  def active_site_with_same_user_and_hostname_exists?(record, new_hostname)
    record.user.sites.not_archived.where { (hostname == new_hostname) & (id != record.id) }.exists?
  end

end
