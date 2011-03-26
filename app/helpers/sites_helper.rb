module SitesHelper

  def sublimevideo_script_tag_for(site)
    %{<script type="text/javascript" src="http://cdn.sublimevideo.net/js/%s.js"></script>} % [site.token]
  end

  def url_with_protocol(url)
    return '' if url.blank?
    (url =~ %r(^https?://) ? '' : 'http://') + url
  end

  def hostname_with_path(site)
    site.path.present? ? "#{site.hostname}/#{site.path}" : site.hostname
  end

  # always with span here
  def hostname_with_path_and_wildcard(site, options = {})
    length = options[:truncate] || 1000
    h_trunc_length = length * 2/3
    p_trunc_length = (site.hostname.length < h_trunc_length) ? (h_trunc_length - site.hostname.length + (length * 1/3)) : (length * 1/3)
    uri = ''
    uri += "<span class='wildcard'>(*.)</span>" if site.wildcard?
    uri += truncate_middle(site.hostname, :length => h_trunc_length)
    uri += "<span class='path'>/#{site.path.truncate(p_trunc_length)}</span>" if site.path.present?
    uri.html_safe
  end

  def display_none_if(condition, value=nil)
    value || "display:none;" unless condition
  end

  def display_text_if(value, condition)
    value if condition
  end

  def display_block_if_or_none_otherwise(condition)
    condition ? "display:block" : "display:none"
  end

  def conditions_for_show_settings(site)
    site.extra_hostnames? \
    || (site.dev_hostnames? && site.dev_hostnames != Site::DEFAULT_DEV_DOMAINS) \
    || site.path? || site.wildcard?
  end

  def conditions_for_show_dev_hostnames_div(site)
    site.dev_hostnames? && site.dev_hostnames != Site::DEFAULT_DEV_DOMAINS
  end
  
  def td_usage_class(site)
    if site.in_paid_plan?
      if site.first_plan_upgrade_required_alert_sent_at?
        "required_upgrade"
      elsif site.plan_player_hits_reached_notification_sent_at? || site.current_monthly_billable_usage > site.plan.player_hits
        "peak_insurance"
      end
    end
  end

end
