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

  def video_stats_hourly_loads_for_chart(stats, source = 'a')
    _reduce_stats_for_field_by_hour(stats, :lo, source)
  end

  def video_stats_hourly_starts_for_chart(stats, source = 'a')
    _reduce_stats_for_field_by_hour(stats, :st, source)
  end

  def video_stats_browsers_and_platforms_stats(stats, source = 'a')
    _reduce_stats_for_field(stats, :bp, source)
  end

  def video_stats_countries_stats(stats, source = 'a')
    _reduce_stats_for_field(stats, :co, source)
  end

  def video_stats_devices_stats(stats, source = 'a')
    _reduce_stats_for_field(stats, :de, source)
  end

  def video_stats_browser_style(browser_and_platform)
    bp = browser_and_platform.split('-')
    icon = if bp[0] == 'saf' && bp[1].in?(%w[iph ipa])
      'saf_mob'
    else
      bp[0]
    end

    "background-image:url(#{asset_path "stats/icons/#{icon}.png"});"
  end

  def video_stats_platform_style(browser_and_platform)
    "background-image:url(#{asset_path "stats/icons/#{browser_and_platform.split('-')[1]}.png"});"
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

  private

  def _reduce_stats_for_field(stats, field, source)
    source = source.to_sym
    Rails.logger.info stats.map { |s| s.send(field) }
    reduced_stats = stats.map { |s| s.send(field) }.compact.reduce(Hash.new(0)) do |memo, stat|
      stat.each do |src, hash|
        next unless source.in?([:a, src.to_sym])

        hash.each do |key, value|
          memo[key] += value
        end
      end
      memo
    end
    reduced_stats = Hash[reduced_stats.sort { |a, b| b[1] <=> a[1] }]

    total = reduced_stats.values.sum
    reduced_stats.map do |k, v|
      reduced_stats[k] = { count: v, percent: v / total.to_f }
    end

    reduced_stats
  end

  def _reduce_stats_for_field_by_hour(stats, field, source)
    source = source.to_s

    stats.map do |stat|
      total = if stat.send(field).present?
        source == 'a' ? (stat.send(field)['w'] || 0) + (stat.send(field)['e'] || 0) : stat.send(field)[source]
      else
        nil
      end

      [Time.parse(stat[:t]).to_i * 1000, total || 0]
    end
  end

end
