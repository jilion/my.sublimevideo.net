module Stat
  extend ActiveSupport::Concern

  included do

    # DateTime periods
    field :s, type: DateTime # Second
    field :m, type: DateTime # Minute
    field :h, type: DateTime # Hour
    field :d, type: DateTime # Day

    field :vv, type: Hash, default: {} # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1, em (embed) => 2 }
    field :md, type: Hash, default: {} # Player Mode + Device { h (html5) => { d (desktop) => 2, m (mobile) => 1 }, f (flash) => ... }
    field :bp, type: Hash, default: {} # Browser + Plateform { "saf-win" => 2, "saf-osx" => 4, ...}

    # ==========
    # = Scopes =
    # ==========

    %w[s m h d].each do |period|
      scope "#{period}_after".to_sym, lambda { |date| where(period => { "$gte" => date.to_i }).order_by([period.to_sym, :asc]) }
      scope "#{period}_before".to_sym,  lambda { |date| where(period => { "$lte" => date.to_i }).order_by([period.to_sym, :asc]) }
      scope "#{period}_between".to_sym, lambda { |start_date, end_date| where(period => { "$gte" => start_date.to_i, "$lte" => end_date.to_i }).order_by([period.to_sym, :asc]) }
    end

  end

  # ====================
  # = Instance Methods =
  # ====================

  def time
    (s || m || h || d).to_i
  end

  # =================
  # = Class Methods =
  # =================
  module ClassMethods

    # Returns the sum of all the usage for the given token(s) (optional) and between the given dates (optional).
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

    def json(site_token, period = 'days')
      if site_token == 'demo'
        site_token = SiteToken.www
        demo       = true
      end
      from, to = period_intervals(site_token, period)

      json_stats = if from.present? && to.present?
        last_stats(token: site_token, period: period, from: from, to: to, fill_missing_days: period != 'seconds', demo: demo)
      else
        []
      end

      json_stats.to_json(only: [:bp, :md])
    end

    def period_intervals(site_token, period)
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
          last_minute_stat = self.where(m: { "$ne" => nil }).order_by([:m, :asc]).last
          to   = last_minute_stat.try(:m) || 1.minute.ago.change(sec: 0)
          from = to - 59.minutes
        end

      when 'hours'
        to   = 1.hour.ago.change(min: 0, sec: 0).utc
        from = to - 23.hours

      when 'days'
        site  = ::Site.find_by_token(site_token)
        stats = self.where(t: site_token, d: { "$ne" => nil }).order_by([:d, :asc])
        to    = 1.day.ago.midnight

        case site.plan_stats_retention_days
        when 0
          to   = nil
          from = nil

        when nil
          from = [(stats.first.try(:d) || Time.now.utc), to - 364.days].min

        else
          from = to - (site.plan_stats_retention_days - 1).days
        end

      end

      [from, to]
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
      conditions.deep_merge!(options[:period].chr.to_sym => { "$gte" => options[:from] }) if options[:from]
      conditions.deep_merge!(options[:period].chr.to_sym => { "$lte" => options[:to] }) if options[:to]
      if options[:demo] && options[:period] == 'days'
        conditions.deep_merge!(options[:period].chr.to_sym => { "$gte" => Time.utc(2011,11,29) }) if options[:from]
      end

      stats = if (!options[:token] && !options[:stats]) || (options[:token] && options[:token].is_a?(Array))
        collection.group(
          key: [options[:period].chr.to_sym],
          cond: conditions,
          initial: { pv: { 'm' => 0, 'e' => 0, 'd' => 0, 'i' => 0, 'em' => 0 }, vv: { 'm' => 0, 'e' => 0, 'd' => 0, 'i' => 0, 'em' => 0 } },
          reduce: js_reduce_for_array(options)
        ).sort_by { |s| s[options[:period].chr] }
      else
        conditions[options[:period].chr.to_sym]["$gte"] = conditions[options[:period].chr.to_sym]["$gte"].to_i if options[:from]
        conditions[options[:period].chr.to_sym]["$lte"] = conditions[options[:period].chr.to_sym]["$lte"].to_i if options[:to]

        (options[:stats] || scoped).where(conditions).order_by([options[:period].chr.to_sym, :asc]).entries
      end

      if !!options[:fill_missing_days]
        options[:missing_days_value] = options[:fill_missing_days].respond_to?(:to_i) ? options[:fill_missing_days] : 0
        self.fill_missing_values_for_last_stats(stats, options)
      else
        stats
      end
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
      period = options[:period].chr

      if !(options[:from] || options[:to])
        options[:from] = stats.min_by { |s| s[period] }[period] || Time.now
        options[:to]   = stats.max_by { |s| s[period] }[period] || (Time.now - 1.second)
      end

      filled_stats, step = [], 1.send(options[:period])
      while options[:from] <= options[:to]
        filled_stats << if stats.first.try(:[], period) == options[:from]
          stats.shift
        else
          self.new(period.to_sym => options[:from].to_time, options[:view_type].to_sym => { options[:field_to_fill] => options[:missing_days_value] })
        end
        options[:from] += step
      end

      filled_stats
    end

  end

  def self.create_stats_from_trackers!(log, trackers)
    tracker_incs = incs_from_trackers(trackers)
    tracker_incs.each do |site_token, values|
      site = ::Site.where(token: site_token).includes(:plan).first

      if (site_inc = values[:inc]).present?
        Stat::Site.collection.update({ t: site_token, m: log.minute }, { "$inc" => site_inc }, upsert: true) unless site.in_free_plan?
        Stat::Site.collection.update({ t: site_token, h: log.hour },   { "$inc" => site_inc }, upsert: true)
        Stat::Site.collection.update({ t: site_token, d: log.day },    { "$inc" => site_inc }, upsert: true)
      end

      values[:videos].each do |video_ui, video_inc|
        if video_inc.present?
          Stat::Video.collection.update({ st: site_token, u: video_ui, m: log.minute }, { "$inc" => video_inc }, upsert: true) unless site.in_free_plan?
          Stat::Video.collection.update({ st: site_token, u: video_ui, h: log.hour },   { "$inc" => video_inc }, upsert: true)
          Stat::Video.collection.update({ st: site_token, u: video_ui, d: log.day },    { "$inc" => video_inc }, upsert: true)
        end
      end
    end

    begin
      json = { m: true }
      json[:h] = true if log.hour == log.minute
      json[:d] = true if log.day == log.hour
      Pusher["stats"].trigger('tick', json)
    rescue Pusher::Error => ex
      Notify.send("Pusher trigger failed", exception: ex)
    end
  end

  def self.delay_clear_old_second_stats
    unless Delayed::Job.already_delayed?('%Stat%clear_old_second_stats%')
      delay(priority: 5, run_at: 1.second.from_now).clear_old_second_stats
    end
  end

  def self.delay_clear_old_minute_stats
    unless Delayed::Job.already_delayed?('%Stat%clear_old_minute_stats%')
      delay(priority: 5, run_at: 1.minute.from_now).clear_old_minute_stats
    end
  end

  def self.delay_clear_old_hour_stats
    unless Delayed::Job.already_delayed?('%Stat%clear_old_hour_stats%')
      delay(priority: 5, run_at: 1.hour.from_now).clear_old_hour_stats
    end
  end

private

  def self.clear_old_second_stats
    delay_clear_old_second_stats

    Stat::Site.s_before(63.seconds.ago).delete_all
    Stat::Video.s_before(63.seconds.ago).delete_all
  end

  def self.clear_old_minute_stats
    delay_clear_old_minute_stats

    Stat::Site.m_before(62.minutes.ago).delete_all
    Stat::Video.m_before(62.minutes.ago).delete_all
  end

  def self.clear_old_hour_stats
    delay_clear_old_hour_stats

    Stat::Site.h_before(26.hours.ago).delete_all
    Stat::Video.h_before(26.hours.ago).delete_all
  end

  # Merge each trackers params on one big hash
  #
  # { 'site_token' => { :inc => {...}, :videos => { 'video_uid' => { inc }, ... } } }
  #
  def self.incs_from_trackers(trackers)
    trackers = only_stats_trackers(trackers)
    incs     = Hash.new { |h,k| h[k] = { inc: Hash.new(0), videos: Hash.new { |h,k| h[k] = Hash.new(0) } } }
    trackers.each do |tracker, hits|
      begin
        request, user_agent = tracker
        params     = Addressable::URI.parse(request).query_values.try(:symbolize_keys) || {}
        params_inc = StatRequestParser.stat_incs(params, user_agent, hits)

        # Site
        site = params_inc[:site]
        if site[:inc].present?
          site[:inc].each do |inc, value|
            incs[site[:t]][:inc][inc] += value
          end
        end

        # Videos
        params_inc[:videos].each do |video|
          if video[:inc].present?
            video[:inc].each do |inc, value|
              incs[video[:st]][:videos][video[:u]][inc] += value
            end
          end
        end
      rescue StatRequestParser::BadParamsError
      rescue TypeError => ex
        Notify.send("Request parsing problem: #{request}", :exception => ex)
      end
    end

    incs
  end

  def self.only_stats_trackers(trackers)
    trackers.detect { |t| t.options[:title] == :stats }.categories
  end

end
