module Admin::SitesHelper

  PAGE_TITLES = {
    tagged_with: "tagged with '%s'",
    with_min_billable_video_views: 'with at least %s video plays in the last 30 days',
    search: "matching '%s'",
    user_id: 'for %s',
    with_state: '%s',
    with_addon_plan: "with the '%s' add-on",
  }

  FILTER_TITLES = {
    addon_plan: '%s (<strong>%s</strong>)'
  }

  def admin_sites_page_title(sites)
    return unless selected_params = _select_param(:free, :paying, :with_extra_hostnames, :with_wildcard, :with_path, :tagged_with, :with_min_billable_video_views, :search, :user_id, :with_state, :with_addon_plan)

    filter_titles = selected_params.reduce([]) do |a, e|
      a << _page_title_from_filter(*e)
    end

    [formatted_pluralize(sites.total_count, 'site').titleize, filter_titles.to_sentence].join(' ')
  end

  def addon_plans_filters
    capture_haml do
      haml_tag(:ul) do
        Addon.public.visible.each do |addon|
          haml_tag(:li, _addon_plans_filter(addon))
        end
      end
    end
  end

  def admin_links_to_hostnames(site)
    html = %w[hostname extra_hostnames dev_hostnames].reduce([]) do |a, e|
      break a if a.any?

      prefix = e == 'hostname' ? nil : "(#{e[0, 3]}) "
      a << [prefix, _joined_hostname_links(site, site.send(e))].compact.join(' ')
    end
    html << "(#{link_to('details', [:edit, :admin, site], title: "EXTRA: #{site.extra_hostnames}; DEV: #{site.dev_hostnames}")})"

    html.join(' ').html_safe
  end

  # always with span here
  def admin_pretty_hostname(site, site_hostname, options = {})
    site_hostname ||= 'no hostname'
    length = options[:truncate] || 1000
    hostname_trunc_length = length * 2 / 3
    path_trunc_length = if site_hostname.size < hostname_trunc_length
      hostname_trunc_length - site_hostname.size + (length * 1 / 3)
    else
      length * 1 / 3
    end
    html = []
    html << '<span class="wildcard">(*.)</span>' if options[:wildcard] && site.wildcard?
    html << truncate_middle(site_hostname, length: hostname_trunc_length)
    html << %(<span class="path">/#{site.path.truncate(path_trunc_length)}</span>) if options[:path] && site.path?

    html.join.html_safe
  end

  def admin_designs_options(site)
    options_for_select(_items_for_select(site, App::Design.order(:price)))
  end

  def admin_addon_plans_options(site)
    grouped_options = {}
    Addon.all.each do |addon|
      if items = _items_for_select(site, addon.plans.includes(:addon).order(:price))
        grouped_options[addon.title] = items
      end
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

  def _select_param(*keys)
    params.select { |k, _| k.to_sym.in?(keys) }
  end

  def _page_title_from_filter(key, value)
    key = key.to_sym
    PAGE_TITLES[key] ? (PAGE_TITLES[key] % _value_for_filter_title_interpolation(key, value)) : _admin_sites_page_title(key)
  end

  def _value_for_filter_title_interpolation(key, value)
    case key
    when :with_min_billable_video_views
      display_integer(value)
    when :user_id
      User.find(value).try(:name_or_email)
    when :with_addon_plan
      AddonPlan.get(*value.split('-')).try(:title)
    else
      value
    end
  end

  def _admin_sites_page_title(underscored_name, value = nil)
    ["#{underscored_name.to_s.gsub(/_/, ' ')}", value].compact.join(' ')
  end

  def _addon_plans_filter(addon)
    addon.plans.includes(:addon).order(:price).reduce([]) do |a, e|
      a << _filter_title_for_addon_plan(e)
    end.join(' | ').html_safe
  end

  def _filter_title_for_addon_plan(addon_plan)
    full_addon_plan_key = "#{addon_plan.addon.name}-#{addon_plan.name}"
    text = FILTER_TITLES[:addon_plan] % [addon_plan.title, display_integer(Site.with_addon_plan(full_addon_plan_key).size)]
    href = admin_sites_path(with_addon_plan: full_addon_plan_key)

    link_to(text.html_safe, href, remote: true, class: 'remote')
  end

  def _joined_hostname_links(site, hostnames)
    hostnames = hostnames.split(/,\s*/)
    return if hostnames.empty?

    first_hostname = hostnames.shift
    html = [link_to(admin_pretty_hostname(site, first_hostname), url_with_protocol(first_hostname))]
    html << "#{hostnames.size} more" unless hostnames.empty?

    html.join(', ')
  end

end
