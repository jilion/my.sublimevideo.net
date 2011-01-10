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
  
  def get_usages_hash(site, options={})
    usages_hash = Hash.new { |h,k| h[k] = {} }
    %w[loader_hits player_hits main_player_hits main_player_hits_cached extra_player_hits extra_player_hits_cached dev_player_hits dev_player_hits_cached invalid_player_hits invalid_player_hits_cached flash_hits requests_s3 traffic_s3 traffic_voxcast].map(&:to_sym).each do |usage_name|
      usages_hash[:total][usage_name] = site.usages.sum(usage_name).to_i

      if options[:last_30_days]
        usages_hash[:last_30_days][usage_name] = site.usages.between(Time.now.utc.beginning_of_day - 30.days, Time.now.utc.beginning_of_day).sum(usage_name).to_i
      end
      
      if options[:from] && options[:to]
        usages_hash[:range][usage_name] = site.usages.between(options[:from], options[:to]).sum(usage_name).to_i
      end
    end
    usages_hash
  end

end
