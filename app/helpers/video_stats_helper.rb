module VideoStatsHelper

  def video_stats_options_for_date_range_select
    options_for_select([
      ['Last 24 hours', 24],
      ['Last 30 days', 30*24],
      ['Last 90 days', 90*24],
      ['Last 365 days', 365*24],
    ], params[:hours])
  end

  def video_stats_options_for_source_select
    options_for_select([
      ['All sources', 'a'],
      ['Your website', 'w'],
      ['External sources', 'e']
    ], params[:source])
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
    browser_and_platform.split('-').map do |name|
      case name
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
      else name
      end
    end.join('<br />').html_safe
  end

end
