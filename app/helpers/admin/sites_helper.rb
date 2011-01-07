module Admin::SitesHelper

  def admin_sites_page_title(sites)
    pluralized_sites = pluralize(sites.total_entries, 'site')
    state = if params[:archived_included]
      " not archived"
    elsif params[:next_plan_recommended_alert_sent_at_alerted_this_month]
      " should upgrade plan"
    else
      ""
    end
    "#{pluralized_sites}#{state}".titleize
  end

  def links_to_hostnames(site)
    html = ""
    if site.hostname?
      html += link_to site.hostname, "http://#{site.hostname}"
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
  end

end
