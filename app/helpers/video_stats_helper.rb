module VideoStatsHelper

  def video_stats_options_for_date_range_select(selected_hours)
    options_for_select([
      ['Last 24 hours', 24],
      ['Last 30 days', 30*24],
      ['Last 90 days', 90*24],
      ['Last 365 days', 365*24],
    ], selected_hours.to_s)
  end

  def video_stats_options_for_source_select(selected_source)
    options_for_select([
      ['All sources', 'a'],
      ['Your website', 'w'],
      ['External websites', 'e']
    ], selected_source)
  end

  def video_stats_sources_for_export_text(source)
    case source
    when 'a'
      'anywhere (on your website and external websites altogether)'
    when 'w'
      'on your website only'
    when 'e'
      'on external websites only'
    end
  end

  def video_stats_browser_style(browser_and_platform)
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

    "background-image:url(#{asset_path "stats/icons/#{icon}.png"});"
  end

  def video_stats_platform_style(browser_and_platform)
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

    "background-image:url(#{asset_path "stats/icons/#{icon}.png"});"
  end

  def video_stats_country_name(country_code)
    country_code = 'gb' if country_code == 'uk'

    Country[country_code].try(:name) || country_code.upcase
  end

  def video_stats_country_style(country_code)
    country_code = 'gb' if country_code == 'uk'

    "background-image:url(#{asset_path("flags/#{country_code.upcase}.png")});"
  end

  def video_stats_browser_and_os_name(browser_and_platform)
    browser_and_platform.split('-').map do |code|
      video_stats_browser_or_os_name(code)
    end.join('<br />').html_safe
  end

  def video_stats_browser_or_os_name(code)
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

end
