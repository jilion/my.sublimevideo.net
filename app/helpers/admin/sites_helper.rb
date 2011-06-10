module Admin::SitesHelper

  def admin_sites_page_title(sites)
    pluralized_sites = pluralize(sites.total_count, 'site')
    state = if params.keys.all? { |k| k =~ /^by_/ || %w[action controller search].include?(k) }
      " not archived"
    elsif params[:with_state]
      " with #{params[:with_state]} state"
    elsif params[:with_wildcard]
      " with wildcard"
    elsif params[:with_path]
      " with path"
    elsif params[:with_extra_hostnames]
      " with extra hostnames"
    elsif params[:with_ssl]
      " with ssl"
    elsif params[:plan_player_hits_reached_notified]
      " notified limit reached this month"
    elsif params[:user_id]
      user = User.find(params[:user_id])
      " for #{user.full_name.titleize}" if user
    elsif params[:search].present?
      " that contains '#{params[:search]}'"
    else
      ""
    end
    "#{pluralized_sites.titleize}#{state}"
  end

  def links_to_hostnames(site)
    html = ""
    if site.hostname?
      html += link_to hostname_with_path_and_wildcard(site), "http://#{site.hostname}"
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
  def hostname_with_path_and_wildcard(site, options = {})
    site_hostname = site.hostname || "no hostname"
    length = options[:truncate] || 1000
    h_trunc_length = length * 2/3
    p_trunc_length = (site_hostname.length < h_trunc_length) ? (h_trunc_length - site_hostname.length + (length * 1/3)) : (length * 1/3)
    uri = ''
    uri += "<span class='wildcard'>(*.)</span>" if site.wildcard?
    uri += truncate_middle(site_hostname, :length => h_trunc_length)
    uri += "<span class='path'>/#{site.path.truncate(p_trunc_length)}</span>" if site.path.present?
    uri.html_safe
  end

end
