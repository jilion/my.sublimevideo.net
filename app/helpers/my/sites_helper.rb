module My::SitesHelper

  def current_password_needed_error?(site)
    site.errors[:base] && site.errors[:base].include?(t('activerecord.errors.models.site.attributes.base.current_password_needed'))
  end

  def full_days_until_trial_end(site)
    if site.trial_not_started_or_in_trial?
      ((site.trial_started_at.midnight + BusinessModel.days_for_trial.days - Time.now.utc.midnight) / (3600 * 24)).to_i
    else
      0
    end
  end

  def trial_will_expire_sentence(site)
    I18n.t('site.trial.will_end', hostname: site.hostname, count: full_days_until_trial_end(site))
  end

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

  def hostname_or_token(site)
    site.hostname.presence || site.token
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

  def td_usage_class(site)
    if site.in_paid_plan? && site.trial_ended?
      if site.first_plan_upgrade_required_alert_sent_at?
        "required_upgrade"
      elsif site.current_monthly_billable_usages.sum > site.plan.video_views
        "peak_insurance"
      end
    end
  end

end
