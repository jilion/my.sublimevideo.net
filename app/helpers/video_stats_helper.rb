module VideoStatsHelper

  def video_browser_and_os_stats(stats)
    _reduce_stats_for_field(stats, :bp)
  end

  def video_countries_stats(stats)
    _reduce_stats_for_field(stats, :co)
  end

  def video_browser_and_os_css_class(browser_and_os_keywork)
    bp = browser_and_os_keywork.split('-')
    "b_#{bp[0]} p_#{bp[1]}"
  end

  def video_stats_country_style(country_code)
    "background-image:url(#{asset_path "flags/#{country_code.upcase}.png"});"
  end

  def video_browser_and_os_name(browser_and_os_keywork)
    browser_and_os_keywork.split('-').map do |name|
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
    end.join(' - ')
  end

  private

  def _reduce_stats_for_field(stats, field)
    a = stats.map { |h| h[field] }.reduce(Hash.new(0)) do |memo, stat|
      stat.each do |source, hash|
        hash.each do |key, value|
          memo[key] += value
        end
      end
      memo
    end

    total = a.values.sum
    a.map do |k, v|
      a[k] = { count: v, percent: v / total.to_f }
    end

    a
  end

end
