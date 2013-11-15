require 'active_support/core_ext'

class StatsPresenter

  attr_reader :resource, :resource_name, :options

  DEFAULT_OPTIONS = {
    source: 'a',
    hours: 24
  }

  # @param [Site, VideoTag] resource the record for which we'll retrieve stats
  # @option options [String] source the source to filter the stats (a => all,
  #   w => website, e => external)
  # @option options [String, Fixnum] hours the number of hours to go back
  # @option options [String] since the timestamp from where to retrieve plays
  #
  # @see SiteStatsPresenter
  # @see VideoStatsPresenter
  #
  def initialize(resource, options = {})
    @resource = resource
    @resource_name = resource.class.to_s.sub(/Tag/, '')
    @options = DEFAULT_OPTIONS.merge(options.symbolize_keys.slice(:source, :hours, :since))
    @options[:hours] = @options[:hours].to_i
  end

  def last_plays
    @last_plays ||= "Last#{resource_name}Play".constantize.last_plays(resource, options[:since])
  end

  def etag
    raise NotImplementedError, "This #{self.class} cannot respond to: #{__method__}"
  end

  def browsers_and_platforms_stats
    @browsers_and_platforms_stats ||= _reduce_stats_for_field(:bp)
  end

  def countries_stats
    @countries_stats ||= _reduce_stats_for_field(:co)
  end

  def devices_stats
    @devices_stats ||= _reduce_stats_for_field(:de)
  end

  def loads
    @loads ||= _reduce_stats_for_field_by_period(:lo)
  end

  def plays
    @plays ||= _reduce_stats_for_field_by_period(:st)
  end

  def last_60_minutes_loads
    @last_60_minutes_loads ||= _last_60_minutes_hits(:lo)
  end

  def last_60_minutes_plays
    @last_60_minutes_plays ||= _last_60_minutes_hits(:st)
  end

  # TODO: Improve
  def last_modified
    stats_for_last_modified = if options[:since]
      _last_stats_by_minute
    else
      _last_stats_by_hour
    end

    stats_for_last_modified.map { |s| s.time }.max
  end

  private

  def _last_stats_by_hour
    @_last_stats_by_hour ||= "#{resource_name}Stat".constantize.last_hours_stats(resource, options[:hours] + 24).reverse
  end

  def _last_stats_by_minute
    @_last_stats_by_minute ||= "Last#{resource_name}Stat".constantize.last_stats(resource).reverse
  end

  def _last_60_minutes_hits(field)
    stats = _last_stats_by_minute.map { |s| [s.time.to_i * 1000, s.send(field)] }

    _group_and_fill_missing_values_for_last_stats(stats,
      period: :minute,
      from: 59.minutes.ago.change(sec: 0),
      to: Time.now.utc.change(sec: 0))
  end

  def _reduce_stats_for_field(field)
    reduced_stats = _last_stats_by_hour.map { |s| s.send(:[], field) }.compact.reduce(Hash.new(0)) do |memo, stat|
      stat.each do |src, hash|
        next unless options[:source].in?(%W[a #{src}])

        hash.each do |key, value|
          key = _handle_special_country_code(key) if field == :co
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
    reduced_stats = _last_stats_by_hour.reduce(Hash.new(0)) do |hash, stat|
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

    from = options[:hours] > 24 ? (options[:hours] + 24).hours.ago.midnight : options[:hours].hours.ago.change(min: 0)
    to   = options[:hours] > 24 ? Time.now.utc.yesterday.midnight : 1.hour.ago.change(min: 0)

    _group_and_fill_missing_values_for_last_stats(reduced_stats.to_a, from: from, to: to)
  end

  def _group_and_fill_missing_values_for_last_stats(stats, opts = {})
    opts = opts.symbolize_keys.reverse_merge(default_value: 0, period: options[:hours] > 24 ? :day : :hour)

    opts[:from] = opts[:from].midnight if opts[:period] == :day

    # ensure stats.first[0] is not < opts[:from]
    stats.shift until stats.empty? || stats.first[0] >= opts[:from].to_i * 1000

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

  def _handle_special_country_code(country_code)
    case country_code.downcase
    when 'fx'
      'fr'
    when 'uk' # British Indian Ocean Territory
      'gb'
    when '--', 'a1', 'a2', 'o1', 'ap' # African Regional Intellectual Property Organization, Guadeloupe, Réunion
      'unknown'
    else
      country_code
    end
  end

end
