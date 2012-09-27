require_dependency 'business_model'

module SitesHelper

  def current_password_needed_error?(site)
    site.errors[:base] && site.errors[:base].include?(t('activerecord.errors.models.site.attributes.base.current_password_needed'))
  end

  def sublimevideo_script_tag_for(site)
    %{<script type="text/javascript" src="//cdn.sublimevideo.net/js/%s.js"></script>} % [site.token]
  end

  def url_with_protocol(url)
    return '' if url.blank?
    (url =~ %r(^https?://) ? '' : 'http://') + url
  end

  def hostname_with_path(site)
    site.path.present? ? "#{site.hostname}/#{site.path}" : site.hostname
  end

  def hostname_or_token(site, options = {})
    options.reverse_merge!(length: 22, prefix: '#')
    name = site.hostname_or_token(options[:prefix])
    truncate_middle name, length: options[:length]
  end

  def display_none_if(condition, value=nil)
    value || "display:none;" unless condition
  end

  def display_text_if(value, condition)
    value if condition
  end

  def style_for_usage_bar_from_usage_percentage(fraction)
    case fraction
    when 0
      "display:none;"
    when 0..0.04
      "width:4%;"
    else
      "width:#{display_percentage(fraction)};"
    end
  end

  def conditions_for_show_settings(site)
    site.extra_hostnames? ||
    (site.dev_hostnames? && site.dev_hostnames != Site::DEFAULT_DEV_DOMAINS) ||
    site.path? || site.wildcard?
  end

  def conditions_for_show_dev_hostnames_div(site)
    site.dev_hostnames? && site.dev_hostnames != Site::DEFAULT_DEV_DOMAINS
  end

  def cdn_up_to_date?(site)
    cdn_updated_at(site) > 0 && cdn_updated_at(site) < 2.minutes.ago.to_i
  end

  def cdn_updated_at(site)
    [site.loaders_updated_at.to_i, site.settings_updated_at.to_i].max
  end

end
