class SiteAdminStatsTimelineBuilder
  attr_accessor :site, :days, :moving_average

  def initialize(site, days: 90, moving_average: 30)
    @site = site
    @days = days
    @moving_average = moving_average
  end

  %w[loads starts].each do |type|
    define_method type do |source = :all|
      send("all_#{type}", source)[moving_average..-1]
    end

    define_method "all_#{type}" do |source = :all|
      _timeline(type, source)
    end
  end

  def start_at
    _date_range.first.to_time + moving_average.days
  end

  def end_at
    _date_range.last.to_time
  end

  private

  def _timeline(type, source)
    _all_stats.map do |stat|
      if source == :all
        stat.send(type).values.sum
      else
        stat.send(type)[source.to_s[0]].to_i
      end
    end
  end

  def _all_stats
    stats = SiteAdminStat.all(site_token: site.token, days: days + moving_average)
    _date_range.map do |date|
      stats.detect { |s| s.date == date } || SiteAdminStat.new(time: date.to_time)
    end
  end

  def _date_range
    (days + moving_average).days.ago.to_date..1.day.ago.to_date
  end

end
