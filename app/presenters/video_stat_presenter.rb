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
    @last_plays ||= LastPlay.last_plays(video_tag, options[:since])
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

  def loads
    _reduce_stats_for_field_by_period(:lo)
  end

  def plays
    _reduce_stats_for_field_by_period(:st)
  end

  def last_60_minutes_loads
    _last_60_minutes_hits(:lo)
  end

  def last_60_minutes_plays
    _last_60_minutes_hits(:st)
  end

  # TODO: Improve
  def last_modified
    stats_for_last_modified = if options[:since]
      last_stats_by_minute
    else
      last_stats_by_hour
    end

    stats_for_last_modified.map { |s| s.time }.max
  end

  def etag
    "#{video_tag.uid}_#{options}"
  end

  private

  def _last_60_minutes_hits(field)
    stats = last_stats_by_minute.map { |s| [s.time.to_i * 1000, s.send(field)] }

    _group_and_fill_missing_values_for_last_stats(stats,
      period: :minute,
      from: 59.minutes.ago.change(sec: 0),
      to: Time.now.utc.change(sec: 0))
  end

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

  def _reduce_stats_for_field_by_period(field)
    reduced_stats = last_stats_by_hour.reduce(Hash.new(0)) do |hash, stat|
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

      time = options[:hours] > 24 ? stat.time.midnight : stat.time
      hash[time.to_i * 1000] += total.to_i

      hash
    end

    _group_and_fill_missing_values_for_last_stats(reduced_stats.to_a,
      from: options[:hours].hours.ago.change(min: 0),
      to: 1.hour.ago.change(min: 0))
  end

  def _group_and_fill_missing_values_for_last_stats(stats, opts = {})
    opts = opts.symbolize_keys.reverse_merge(default_value: 0, period: options[:hours] > 24 ? :day : :hour)

    if !opts[:from] && !opts[:to]
      opts[:from] = stats.first[0] || Time.now
      opts[:to]   = stats.last[0] || (Time.now - 1.second)
    end
    opts[:from] = opts[:from].midnight if opts[:period] == :day

    filled_stats, step = [], 1.send(opts[:period])
    while opts[:from] <= opts[:to]
      js_time = opts[:from].to_i * 1000
      filled_stats << if stats.first && stats.first[0] == js_time
        stats.shift
      else
        [js_time, opts[:default_value]]
      end
      opts[:from] += step
    end

    filled_stats
  end

end
