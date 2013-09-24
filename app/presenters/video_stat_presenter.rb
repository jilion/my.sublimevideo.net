require 'active_support/core_ext'

class VideoStatPresenter

  attr_reader :video_tag, :options

  DEFAULT_OPTIONS = {
    source: 'a',
    hours: 24
  }

  def initialize(video_tag, options = {})
    @video_tag = video_tag
    @options = DEFAULT_OPTIONS.merge(options.symbolize_keys.slice(:source, :hours, :since))
    @options[:hours] = @options[:hours].to_i
  end

  def last_stats_by_hour
    @last_stats_by_hour ||= VideoStat.last_hours_stats(video_tag, options[:hours])
  end

  def last_stats_by_minute
    @last_stats_by_minute ||= LastVideoStat.last_stats(video_tag)
  end

  def last_plays
    @last_plays ||= LastVideoPlay.last_plays(video_tag, options[:since])
  end

  def browsers_and_platforms_stats
    _reduce_stats_for_field(:bp)
  end

  def countries_stats
    _reduce_stats_for_field(:co)
  end

  def devices_stats
    _reduce_stats_for_field(:de)
  end

  def hourly_loads
    _reduce_stats_for_field_by_hour(:lo)
  end

  def hourly_starts
    _reduce_stats_for_field_by_hour(:st)
  end

  def last_60_minutes_loads
    stats = last_stats_by_minute.map { |s| [Time.parse(s.t).to_i * 1000, s.lo] }

    _fill_missing_values_for_last_stats(stats,
      period: :minute,
      from: 60.minutes.ago.change(sec: 0),
      to: 1.minute.ago.change(sec: 0))
  end

  def last_60_minutes_starts
    stats = last_stats_by_minute.map { |s| [Time.parse(s.t).to_i * 1000, s.st] }

    _fill_missing_values_for_last_stats(stats,
      period: :minute,
      from: 60.minutes.ago.change(sec: 0),
      to: 1.minute.ago.change(sec: 0))
  end

  private

  def _reduce_stats_for_field(field)
    reduced_stats = last_stats_by_hour.map { |s| s.send(:[], field) }.compact.reduce(Hash.new(0)) do |memo, stat|
      stat.each do |src, hash|
        next unless options[:source].in?(%W[a #{src}])

        hash.each do |key, value|
          memo[key] += value
        end
      end
      memo
    end
    reduced_stats = Hash[reduced_stats.sort { |a, b| b[1] <=> a[1] }]

    total = reduced_stats.values.reduce(0) { |sum, e| sum += e }
    reduced_stats.map do |k, v|
      reduced_stats[k] = { count: v, percent: v / total.to_f }
    end

    reduced_stats
  end

  def _reduce_stats_for_field_by_hour(field)
    reduced_stats = last_stats_by_hour.map do |stat|
      stat_for_field = stat.send(:[], field)
      total = if stat_for_field.present?
        if options[:source] == 'a'
          (stat_for_field['w'] || 0) + (stat_for_field['e'] || 0)
        else
          stat_for_field[options[:source]]
        end
      else
        0
      end

      [Time.parse(stat.t).to_i * 1000, total || 0]
    end

    _fill_missing_values_for_last_stats(reduced_stats,
      period: :hour,
      from: options[:hours].to_i.hours.ago.change(min: 0),
      to: 1.hour.ago.change(min: 0))
  end

  def _fill_missing_values_for_last_stats(stats, options = {})
    options = options.symbolize_keys.reverse_merge(default_value: 0)

    if !options[:from] && !options[:to]
      options[:from] = stats.first[0] || Time.now
      options[:to]   = stats.last[0] || (Time.now - 1.second)
    end

    filled_stats, step = [], 1.send(options[:period])
    while options[:from] <= options[:to]
      js_time = options[:from].to_i * 1000
      filled_stats << if stats.first && stats.first[0] == js_time
        stats.shift
      else
        [js_time, options[:default_value]]
      end
      options[:from] += step
    end

    filled_stats
  end

end
