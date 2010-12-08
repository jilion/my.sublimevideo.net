module Admin::SitesHelper
  
  def admin_sites_page_title(sites)
    states = (params[:archived_included] ? [] : ["active"])
    # states << "with activity" if params[:with_activity].present?
    "#{sites.total_entries} #{states.join(' & ')} sites".titleize
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