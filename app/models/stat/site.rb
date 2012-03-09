module Stat::Site
  extend ActiveSupport::Concern
  include Stat

  included do
    field :t, type: String    # Site token

    field :pv, type: Hash, default: {} # Page Visits: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2, em (embed) => 2 }

    index [[:t, Mongo::ASCENDING], [:d, Mongo::ASCENDING]]
  end

  # ====================
  # = Instance Methods =
  # ====================

  def site
    Site.find_by_token(t)
  end

  def token
    read_attribute(:t)
  end

  # only main & extra hostname are counted in charts
  def chart_pv
    pv['m'].to_i + pv['e'].to_i
  end

  # only main & extra hostname are counted in charts
  def chart_vv
    vv['m'].to_i + vv['e'].to_i
  end

  # main & extra hostname, with main & extra embed
  def billable_vv
    chart_vv + vv['em'].to_i
  end

  # send time as id for backbonejs model
  def as_json(options = nil)
    json = super
    json['id']  = time
    json['pv']  = chart_pv unless chart_pv.zero?
    json['vv']  = chart_vv unless chart_vv.zero?
    json['bvv'] = billable_vv if d? && !billable_vv.zero?
    json
  end

  # =================
  # = Class Methods =
  # =================
  module ClassMethods

    # Returns the sum of all the day usage for the given token(s) (optional) and between the given dates (optional).
    #
    # @option options [String] token a valid site token
    # @option options [Array<String>] token an array of valid site tokens
    # @option options [String] view_type the type of views to fetch. Can be 'vv' (Video Views, default) or 'pv' (Page Visits).
    # @option options [DateTime] from represents the datetime from where returning stats
    # @option options [DateTime] to represents the datetime to where returning stats
    # @option options [String] billable_only if true, return only the sum for billable fields
    #
    # @return [Integer] the sum of views
    #
    def views_sum(options = {})
      options = options.symbolize_keys.reverse_merge(view_type: 'vv', billable_only: false)

      conditions = {}
      conditions[:t] = { "$in" => Array.wrap(options[:token]) }        if options[:token]
      conditions.deep_merge!(d: { "$gte" => options[:from].midnight }) if options[:from]
      conditions.deep_merge!(d: { "$lte" => options[:to].end_of_day }) if options[:to]

      stats = collection.group(
        key: nil,
        cond: conditions,
        initial: { sum: 0 },
        reduce: js_reduce_for_sum(options)
      )

      stats.any? ? stats.first['sum'].to_i : 0
    end

    # Returns an array of Stat::Site objects.
    #
    # @option options [String] token a valid site token
    # @option options [Array<String>] token an array of valid site tokens
    # @option options [Array<Stat::Site>] stats an array of Stat::Site objects
    # @option options [String] view_type the type of views to fetch. Can be 'vv' (Video Views, default) or 'pv' (Page Visits).
    # @option options [String] period the precision desired, can be 'days' (default), 'hours', 'minutes', 'seconds'
    # @option options [DateTime] from represents the datetime from where returning stats
    # @option options [DateTime] to represents the datetime to where returning stats
    # @option options [Boolean] fill_missing_days when true, missing days will be "filled" with 0 main views
    # @option options [Integer] fill_missing_days missing days will be "filled" with the given value as main views
    #
    # @return [Array<Stat::Site>] an array of Stat::Site objects
    #
    def last_stats(options = {})
      options = options.symbolize_keys.reverse_merge(view_type: 'vv', period: 'days', fill_missing_days: true)

      conditions = {}
      conditions[:t] = { "$in" => Array.wrap(options[:token]) } if options[:token]
      conditions.deep_merge!(d: { "$gte" => options[:from] }) if options[:from]
      conditions.deep_merge!(d: { "$lte" => options[:to] }) if options[:to]
      if options[:demo] && options[:period] == 'days'
        conditions.deep_merge!(d: { "$gte" => Time.utc(2011,11,29) }) if options[:from]
      end

      stats = if (!options[:token] && !options[:stats]) || (options[:token] && options[:token].is_a?(Array))
        collection.group(
          key: [:d],
          cond: conditions,
          initial: { pv: { 'm' => 0, 'e' => 0, 'd' => 0, 'i' => 0, 'em' => 0 }, vv: { 'm' => 0, 'e' => 0, 'd' => 0, 'i' => 0, 'em' => 0 } },
          reduce: js_reduce_for_array(options)
        ).sort_by { |s| s[:d] }
      else
        conditions[:d]["$gte"] = conditions[:d]["$gte"].to_i if options[:from]
        conditions[:d]["$lte"] = conditions[:d]["$lte"].to_i if options[:to]

        (options[:stats] || scoped).where(conditions).order_by([:d, :asc]).entries
      end

      if !!options[:fill_missing_days]
        options[:missing_days_value] = options[:fill_missing_days].respond_to?(:to_i) ? options[:fill_missing_days] : 0
        fill_missing_values_for_last_stats(stats, options)
      else
        stats
      end
    end

  private

    def js_reduce_for_sum(options = {})
      options = options.symbolize_keys.reverse_merge(billable_only: false)

      fields = %w[m e em] # billable fields: main, extra and embed
      fields << 'd' unless options[:billable_only] # add dev views if billable_only is false
      reduce_function = ["function(doc, prev) {"]
      fields.inject(reduce_function) do |js, field_to_merge|
        js << "prev.sum += doc.#{options[:view_type]} ? (isNaN(doc.#{options[:view_type]}.#{field_to_merge}) ? 0 : doc.#{options[:view_type]}.#{field_to_merge}) : 0;"
        js
      end

      (reduce_function << "}").join(' ')
    end

    def js_reduce_for_array(options = {})
      options = options.symbolize_keys.reverse_merge(billable_only: false)

      fields = %w[m e em] # billable fields: main, extra and embed
      fields << 'd' unless options[:billable_only] # add dev views if billable_only is false
      reduce_function = ["function(doc, prev) {"]
      fields.inject(reduce_function) do |js, field_to_merge|
        js << "prev.#{options[:view_type]}.#{field_to_merge} += doc.#{options[:view_type]} ? (isNaN(doc.#{options[:view_type]}.#{field_to_merge}) ? 0 : doc.#{options[:view_type]}.#{field_to_merge}) : 0;"
        js
      end

      (reduce_function << "}").join(' ')
    end

    def fill_missing_values_for_last_stats(stats, options = {})
      options = options.symbolize_keys.reverse_merge(field_to_fill: 'm', missing_days_value: 0)

      if !(options[:from] || options[:to])
        options[:from] = stats.min_by { |s| s['d'] }['d'] || Time.now
        options[:to]   = stats.max_by { |s| s['d'] }['d'] || (Time.now - 1.second)
      end

      filled_stats, step = [], 1.send(options[:period])
      while options[:from] <= options[:to]
        filled_stats << if stats.first.try(:[], 'd') == options[:from]
          stats.shift
        else
          self.new(d: options[:from].to_time, options[:view_type].to_sym => { options[:field_to_fill] => options[:missing_days_value] })
        end
        options[:from] += step
      end

      filled_stats
    end

  end

  def self.json(site_token, period = 'days')
    if site_token == 'demo'
      site_token = SiteToken.www
      demo       = true
    end
    from, to = period_intervals(site_token, period)

    json_stats = if from.present? && to.present?
      case period
      when 'seconds'
        Stat::Site::Second.last_stats(token: site_token, period: period, from: from, to: to, fill_missing_days: false, demo: demo)
      when 'minutes'
        Stat::Site::Minute.last_stats(token: site_token, period: period, from: from, to: to, fill_missing_days: true, demo: demo)
      when 'hours'
        Stat::Site::Hour.last_stats(token: site_token, period: period, from: from, to: to, fill_missing_days: true, demo: demo)
      when 'days'
        Stat::Site::Day.last_stats(token: site_token, period: period, from: from, to: to, fill_missing_days: true, demo: demo)
      end
    else
      []
    end

    json_stats.to_json(only: [:bp, :md])
  end

private

  def self.period_intervals(site_token, period)
    case period
    when 'seconds'
      to    = 2.seconds.ago.change(usec: 0).utc
      from  = to - 59.seconds
    when 'minutes'
      site  = ::Site.find_by_token(site_token)
      if site.plan_stats_retention_days == 0
        to   = nil
        from = nil
      else
        last_minute_stat = Stat::Site::Minute.order_by([:d, :asc]).last
        to   = last_minute_stat.try(:d) || 1.minute.ago.change(sec: 0)
        from = to - 59.minutes
      end
    when 'hours'
      to   = 1.hour.ago.change(min: 0, sec: 0).utc
      from = to - 23.hours
    when 'days'
      site  = ::Site.find_by_token(site_token)
      stats = Stat::Site::Day.where(t: site_token).order_by([:d, :asc])
      to    = 1.day.ago.midnight
      case site.plan_stats_retention_days
      when 0
        to   = nil
        from = nil
      when nil
        from = [(stats.first.d || Time.now.utc), to - 364.days].min
      else
        from = to - (site.plan_stats_retention_days - 1).days
      end
    end

    [from, to]
  end


end

