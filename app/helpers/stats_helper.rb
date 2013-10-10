module StatsHelper

  def pusher_channel
    name = [@site.token, @video_tag.try(:uid)].compact.join('.')
    "private-#{name}"
  end

  def stats_hours_range_hash
    {
      24 => '24 hours',
      (30.days / 1.hour) => '30 days',
      (90.days / 1.hour) => '90 days',
      (365.days / 1.hour) => '365 days'
    }
  end

  def stats_sources_hash
    {
      'a' => 'all sites',
      'w' => 'your site',
      'e' => 'other sites'
    }
  end

  def stats_hours_range_select(selected_hours)
    ranges = stats_hours_range_hash
    ranges.delete(selected_hours)

    ranges
  end

  def stats_source_select(selected_source)
    sources = stats_sources_hash
    sources.delete(selected_source)

    sources
  end

  def stats_hours_or_days(hours)
    if hours > 24
      pluralize(hours / 24, 'day')
    else
      pluralize(hours, 'hour')
    end
  end

  def stats_sources_for_export_text(source)
    case source
    when 'a'
      'anywhere (on your site and external sources altogether)'
    when 'w'
      'on your site only'
    when 'e'
      'on external sources only'
    end
  end

  def stats_browser_style(browser_and_platform)
    bp = browser_and_platform.split('-')
    browser = if bp[0] == 'saf' && bp[1].in?(%w[iph ipa ipo])
      'saf_mob'
    else
      bp[0]
    end
    icon = case browser
    when 'rim'
      'bro'
    else
      browser
    end

    "background-image:url(#{asset_path("stats/icons/#{icon}.png")});"
  end

  def stats_platform_style(browser_and_platform)
    platform = browser_and_platform.split('-')[1]
    icon = case platform
    when 'ipo'
      'iph'
    when 'wip'
      'win'
    when 'rim', 'otd', 'otm'
      'oth'
    else
      platform
    end

    "background-image:url(#{asset_path("stats/icons/#{icon}.png")});"
  end

  def stats_country_name(country_code)
    Country[country_code].try(:name) || _handle_special_country_code_for_name(country_code)
  end

  def stats_country_style(country_code)
    "background-image:url(#{asset_path("flags/#{_handle_special_country_code_for_flag(country_code).upcase}.png")});"
  end

  def stats_class_for_visual_percentage(decimal)
    "percent_#{(decimal * 100).to_i}"
  end

  def stats_style_for_horizontal_visual_percentage(decimal)
    "width: #{decimal * 100}%;"
  end

  def stats_height_style_for_mobile_desktop_percentage(decimal)
    "height: #{decimal * 100}%;"
  end

  def stats_line_height_style_for_mobile_desktop_percentage(decimal, offset = 0)
    "line-height: #{(493 * decimal + offset).floor}px;"
  end

  def stats_browser_and_os_name(browser_and_platform)
    browser_and_platform.split('-').map do |code|
      stats_browser_or_os_name(code)
    end.join('<br />').html_safe
  end

  def stats_browser_or_os_name(code)
    case code
    when 'fir' then 'Firefox'
    when 'chr' then 'Chrome'
    when 'iex' then 'IE'
    when 'saf' then 'Safari'
    when 'and' then 'Android'
    when 'rim' then 'BlackBerry'
    when 'weo' then 'webOS'
    when 'ope' then 'Opera'
    when 'win' then 'Windows'
    when 'osx' then 'Macintosh'
    when 'ipa' then 'iPad'
    when 'iph' then 'iPhone'
    when 'ipo' then 'iPod'
    when 'lin' then 'Linux'
    when 'wip' then 'Windows Phone'
    when 'oth' then 'Other'
    when 'otm' then 'Other (Mobile)'
    when 'otd' then 'Other (Desktop)'
    else code
    end
  end

  private

  def _handle_special_country_code_for_name(country_code)
    case country_code
    when 'eu'
      'Europe'
    when 'ap'
      'Asia/Pacific Region'
    else
      country_code.titleize
    end
  end

  def _handle_special_country_code_for_flag(country_code)
    case country_code
    when 'gp', 're', 'io', 'ap' # No flags for Guadeloupe, Reunion, British Indian Ocean Territory, Asia/Pacific Region
      'unknown'
    else
      country_code
    end
  end

end
