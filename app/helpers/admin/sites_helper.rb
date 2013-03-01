module Admin::SitesHelper

  def admin_sites_page_title(sites)
    state = if param = params.detect { |k, v| k.to_sym.in?([:free, :paying, :with_extra_hostnames, :with_wildcard, :with_path]) }
      _admin_sites_page_title(param[0])
    elsif params[:tagged_with]
      _admin_sites_page_title('tagged_with', "'#{params[:tagged_with]}'")
    elsif params[:with_min_billable_video_views]
      "with at least #{display_integer(params[:with_min_billable_video_views])} video plays in the last 30 days"
    elsif params[:search].present?
      "matching '#{params[:search]}'"
    elsif params[:user_id]
      user = User.find(params[:user_id])
      "for #{user.name_or_email}" if user
    elsif params[:with_state]
      "#{params[:with_state]}"
    elsif params[:with_addon_plan]
      "with the '#{AddonPlan.get(*params[:with_addon_plan].split('-')).title}' add-on"
    end

    [formatted_pluralize(sites.total_count, 'site').titleize, state].join(' ')
  end

  def addon_plans_list_for(addon)
    addon.plans.includes(:addon).order(:price).inject([]) do |memo, addon_plan|
      count_of_sites_with_this_addon_plan = Site.with_addon_plan("#{addon.name}-#{addon_plan.name}").size
      text = "#{addon_plan.title} (#{content_tag(:strong, display_integer(count_of_sites_with_this_addon_plan))})".html_safe
      href = admin_sites_path(with_addon_plan: "#{addon.name}-#{addon_plan.name}")
      memo << link_to(text, href, remote: true, class: 'remote')
    end.join(' | ').html_safe
  end

  def links_to_hostnames(site)
    html = ""
    if site.hostname?
      html += link_to truncated_hostname(site), url_with_protocol(site.hostname)
    elsif site.extra_hostnames?
      html += "(ext) #{joined_links(site.extra_hostnames)}"
    else
      html += "(dev) #{joined_links(site.dev_hostnames)}"
    end
    html += " (#{link_to("details", [:edit, :admin, site], title: "EXTRA: #{site.extra_hostnames}; DEV: #{site.dev_hostnames}")})"
    raw html
  end

  def joined_links(hostnames)
    return if hostnames.empty?

    hostnames = hostnames.split(/,\s*/)
    first_hostname = hostnames.shift
    html = link_to first_hostname, "http://#{first_hostname}"
    html += ", #{hostnames.size} more" unless hostnames.empty?
    html
  end

  # always with span here
  def truncated_hostname(site, options = {})
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

  def app_designs_for_admin_select(site)
    items = _items_for_select(site, App::Design.order(:price))
    options_for_select(items)
  end

  def addon_plans_for_select(site)
    grouped_options = {}
    addons = Addon.all

    addons.each do |addon|
      items = _items_for_select(site, addon.plans.includes(:addon).order(:price))
      grouped_options[addon.title] = items if items.present?
    end

    grouped_options_for_select(grouped_options)
  end

  private

  def _items_for_select(site, scope)
    scope.map do |item|
      title = if billable_item = site.billable_items.with_item(item).first
        "#{item.title} (#{billable_item.state})"
      else
        item.title
      end
      [title, item.id]
    end
  end

  def _admin_sites_page_title(underscored_name, value = nil)
    ["#{underscored_name.gsub(/_/, ' ')}", value].compact.join(' ')
  end

end
