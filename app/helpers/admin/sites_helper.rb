module Admin::SitesHelper

  def admin_sites_page_title(sites)
    state = if params[:in_plan]
      " in #{"trial of " if params[:in_trial]}the #{params[:in_plan].titleize} plan"
    elsif params[:paid_plan]
      params[:in_trial] ? " in trial" : " paying"
    elsif params[:overusage_notified]
      " with peak insurance"
    elsif params[:with_next_cycle_plan]
      " will downgrade"
    elsif params[:with_extra_hostnames]
      " with extra hostnames"
    elsif params[:with_wildcard]
      " with wildcard"
    elsif params[:with_path]
      " with path"
    elsif params[:badged]
      " with#{'out' if params[:badged] == 'false'} badge"
    elsif params[:tagged_with]
      " tagged with '#{params[:tagged_with]}'"
    elsif params[:with_min_billable_video_views]
      " with more than #{display_integer(params[:with_min_billable_video_views])} video plays in the last 30 days"
    elsif params[:search].present?
      " matching '#{params[:search]}'"
    elsif params[:user_id]
      user = User.find(params[:user_id])
      " for #{user.name_or_email}" if user
    elsif params[:with_state]
      " #{params[:with_state]}"
    end

    "#{formatted_pluralize(sites.total_count, 'site').titleize}#{state}"
  end

  def links_to_hostnames(site)
    html = ""
    if site.hostname?
      html += link_to truncated_hostname(site), "http://#{site.hostname}"
    elsif site.extra_hostnames?
      html += "(ext) #{joined_links(site.extra_hostnames)}"
    else
      html += "(dev) #{joined_links(site.dev_hostnames)}"
    end
    html += " (#{link_to("details", [:edit, :admin, site], :title => "EXTRA: #{site.extra_hostnames}; DEV: #{site.dev_hostnames}")})"
    raw html
  end

  def joined_links(hostnames)
    return if hostnames.empty?

    hostnames = hostnames.split(',')
    first_hostname = hostnames.shift
    html = link_to first_hostname, "http://#{first_hostname}"
    html += ", #{hostnames.size} more" unless hostnames.empty?
    html
  end

  # always with span here
  def truncated_hostname(site, options={})
    site_hostname = site.hostname || "no hostname"
    length = options[:truncate] || 1000
    h_trunc_length = length * 2/3
    p_trunc_length = (site_hostname.length < h_trunc_length) ? (h_trunc_length - site_hostname.length + (length * 1/3)) : (length * 1/3)
    uri = ''
    uri += "<span class='wildcard'>(*.)</span>" if options[:wildcard] && site.wildcard?
    uri += truncate_middle(site_hostname, length: h_trunc_length)
    uri += "<span class='path'>/#{site.path.truncate(p_trunc_length)}</span>" if options[:path] && site.path.present?
    uri.html_safe
  end

end
