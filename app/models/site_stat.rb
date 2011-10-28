class SiteStat
  include Mongoid::Document

  field :t,  type: String # Site token

  # DateTime periods
  field :s,  type: DateTime  # Second
  field :m,  type: DateTime  # Minute
  field :h,  type: DateTime  # Hour
  field :d,  type: DateTime  # Day

  field :pv, type: Hash, default: {} # Page Visits: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2, em (embed) => 3 }
  field :vv, type: Hash, default: {} # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1, em (embed) => 3 }
  field :md, type: Hash              # Player Mode + Device hash { h (html5) => { d (desktop) => 2, m (mobile) => 1, t (tablet) => 1 }, f (flash) => ... }
  field :bp, type: Hash              # Browser + Plateform hash { "saf-win" => 2, "saf-osx" => 4, ...}

  index :t
  index [[:t, Mongo::ASCENDING], [:s, Mongo::ASCENDING]]#, :unique => true
  index [[:t, Mongo::ASCENDING], [:m, Mongo::ASCENDING]]#, :unique => true
  index [[:t, Mongo::ASCENDING], [:h, Mongo::ASCENDING]]#, :unique => true
  index [[:t, Mongo::ASCENDING], [:d, Mongo::ASCENDING]]#, :unique => true

  # Associations

  def site
    Site.find_by_token(t)
  end

  # Scopes

  %w[s m h d].each do |period|
    scope "#{period}_after".to_sym, lambda { |date| where(period => { "$gte" => date.to_i }).order_by([period.to_sym, :asc]) }
    scope "#{period}_before".to_sym,  lambda { |date| where(period => { "$lte" => date.to_i }).order_by([period.to_sym, :asc]) }
    scope "#{period}_between".to_sym, lambda { |start_date, end_date| where(period => { "$gte" => start_date.to_i, "$lte" => end_date.to_i }).order_by([period.to_sym, :asc]) }
  end

  def token
    read_attribute(:t)
  end

  def time
    (s || m || h || d).to_i
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
    vv['m'].to_i + vv['e'].to_i + vv['em'].to_i
  end

  # send time as id for backbonejs model
  def as_json(options = nil)
    json = super
    json['id']  = time
    json['pv']  = chart_pv if chart_pv > 0
    json['vv']  = chart_vv if chart_vv > 0
    json['bvv'] = billable_vv if d.present? && billable_vv > 0
    json
  end

  # Returns an array of SiteStat objects.
  #
  # @option options [String] token a valid site token
  # @option options [Array<String>] token an array of valid site tokens
  # @option options [Array<SiteStat>] stats an array of SiteStat objects
  # @option options [String] period_type the precision desired, can be 'days' (default), 'hours', 'minutes', 'seconds'
  # @option options [DateTime] from represents the datetime from where returning stats
  # @option options [DateTime] to represents the datetime to where returning stats
  # @option options [Boolean] fill_missing_days when true, missing days will be "filled" with 0 main views
  # @option options [Integer] fill_missing_days missing days will be "filled" with the given value as main views
  # @return [Array<SiteStat>] an array of SiteStat objects
  #
  def self.last_stats(options = {})
    options = options.symbolize_keys.reverse_merge(period_type: 'days', fill_missing_days: true)

    stats = options[:token] ? self.where(t: { "$in" => Array.wrap(options[:token]) }) : options[:stats]
    stats = stats.send("#{options[:period_type].chr}_between", options[:from], options[:to]) if options[:from] && options[:to]
    stats = stats.only(:d, options[:type].to_sym) if options[:type]
    stats = stats.asc(:d).entries

    if !!options[:fill_missing_days]
      options[:missing_days_value] = options[:fill_missing_days].respond_to?(:to_i) ? options[:fill_missing_days] : 0
      fill_missing_values_for_last_stats(stats, options[:period_type], options)
    else
      stats
    end
  end

  def self.last_days(options = {})
    options = options.symbolize_keys.reverse_merge(days: 30)

    last_stats(options.merge(from: options[:days].days.ago.midnight, to: 1.day.ago.midnight))
  end

  # Returns an array of SiteStat objects found by day.
  #
  # @option options [String] type the type of views to fetch. Can be 'vv' (Video Views, default) or 'pv' (Page Visits).
  # @option options [String] token a valid site token
  # @option options [Array<String>] token an array of valid site tokens
  # @option options [DateTime] from represents the datetime from where returning stats
  # @option options [DateTime] to represents the datetime to where returning stats
  # @option options [String] billable if true, merge the main and extra views into a single billable field
  # @option options [Boolean] fill_missing_days when true, missing days will be "filled" with 0 main views
  # @option options [Integer] fill_missing_days missing days will be "filled" with the given value as main views
  # @return [Array<SiteStat>] an array of SiteStat objects
  #
  def self.all_by_days(options = {})
    options = options.symbolize_keys.reverse_merge(type: 'vv', billable: false)

    if options[:billable]
      conditions = options[:token] ? { t: { "$in" => Array.wrap(options[:token]) }, d: { "$ne" => nil } } : {}
      conditions.merge!(d: { "$gte" => options[:from].midnight }) if options[:from]
      conditions.deep_merge!(d: { "$lte" => options[:to].end_of_day }) if options[:to]

      stats = collection.group(
        :key => [:d],
        :cond => conditions,
        :initial => { billable: 0 },
        :reduce => js_billable_reduce_function(options[:type])
      )

      options[:fill_missing_days] ? fill_missing_values_for_last_stats(stats, 'days', 0) : stats
    else
      token_or_stats = options[:token] ? { token: options[:token] } : { stats: scoped }
      self.last_stats(options.merge(token_or_stats))
    end
  end

  def self.all_time_sum(options = {})
    options = options.symbolize_keys.reverse_merge(type: 'vv', billable: false)

    all_time_stats = all_by_days(options)

    if options[:billable]
      all_time_stats.sum { |s| s['billable'] }.to_i
    else
      all_time_stats.sum { |s| s.send(options[:type])['m'].to_i + s.send(options[:type])['e'].to_i + s.send(options[:type])['em'].to_i + s.send(options[:type])['d'].to_i }
    end
  end

  def self.json(token, period_type = 'days')
    json_stats = case period_type
    when 'seconds'
      to    = Time.now.change(usec: 0).utc
      from  = to - 60.seconds # pass 61 seconds

      last_stats(token: token, period_type: period_type, from: from, to: to)

    when 'minutes'
      last_minute_stat = self.where(m: { "$ne" => nil }).order_by([:m, :asc]).last
      to   = last_minute_stat.try(:m) || 1.minute.ago.change(sec: 0)
      from = to - 59.minutes

      last_stats(token: token, period_type: period_type, from: from, to: to)

    when 'hours'
      to   = 1.hour.ago.change(min: 0, sec: 0).utc
      from = to - 23.hours

      last_stats(token: token, period_type: period_type, from: from, to: to)

    when 'days'
      site  = Site.find_by_token(token)
      Rails.logger.debug "site.stats_retention_days: #{site.stats_retention_days}"
      stats = self.where(t: token, d: { "$ne" => nil }).order_by([:d, :asc])
      to    = 1.day.ago.midnight
      case site.stats_retention_days
      when 0
        []
      when nil
        from = [(stats.first.try(:d) || Time.now.utc), to - 364.days].min
        last_stats(stats: stats, period_type: period_type, from: from, to: to)
      else
        from = to - (site.stats_retention_days - 1).days
        last_stats(stats: stats, period_type: period_type, from: from, to: to)
      end
    end

    json_stats.to_json(only: [:bp, :md])
  end

  def self.create_stats_from_trackers!(log, trackers)
    incs = incs_from_trackers(trackers)
    incs.each do |token, inc|
      self.collection.update({ t: token, m: log.minute }, { "$inc" => inc }, upsert: true)
      self.collection.update({ t: token, h: log.hour },   { "$inc" => inc }, upsert: true)
      self.collection.update({ t: token, d: log.day },    { "$inc" => inc }, upsert: true)
    end
    begin
      json = {}
      json[:h] = true if log.hour == log.minute
      json[:d] = true if log.day == log.hour
      Pusher["stats"].trigger('tick', json)
    rescue Pusher::Error => ex
      Notify.send("Pusher trigger failed", exception: ex)
    end
  end

  def self.delay_clear_old_seconds_minutes_and_days_stats
    unless Delayed::Job.already_delayed?('%SiteStat%clear_old_seconds_minutes_and_days_stats%')
      delay(priority: 100, run_at: 1.minutes.from_now).clear_old_seconds_minutes_and_days_stats
    end
  end

  def self.clear_old_seconds_minutes_and_days_stats
    delay_clear_old_seconds_minutes_and_days_stats
    self.s_before(62.seconds.ago).delete_all
    self.m_before(61.minutes.ago).delete_all
    self.h_before(25.hours.ago).delete_all
  end

private

  def self.js_billable_reduce_function(field_type = 'vv')
    reduce_function = ["function(doc, prev) {"]

    %w[m e em].inject(reduce_function) do |js, field_to_merge|
      js << "prev.billable += (isNaN(doc.vv.#{field_to_merge}) ? 0 : doc.vv.#{field_to_merge});"
      js
    end

    (reduce_function << "}").join(' ')
  end

  def self.fill_missing_values_for_last_stats(stats, period_type, options = {})
    options = options.symbolize_keys.reverse_merge(field_to_fill: 'm', missing_days_value: 0)

    if !(options[:from] || options[:to])
      options[:from] = stats.min_by { |s| s.d }.d || Time.now
      options[:to]   = stats.max_by { |s| s.d }.d || (Time.now - 1.second)
    end

    filled_stats, step = [], 1.send(period_type)
    while options[:from] <= options[:to]
      filled_stats << if stats.first.try(period_type.chr) == options[:from]
        stats.shift
      else
        self.new(period_type.chr.to_sym => options[:from].to_time, pv: { options[:field_to_fill] => options[:missing_days_value] })
      end
      options[:from] += step
    end

    filled_stats
  end

  def self.incs_from_trackers(trackers)
    trackers = trackers.detect { |t| t.options[:title] == :stats }.categories
    incs     = Hash.new { |h,k| h[k] = Hash.new(0) }
    trackers.each do |tracker, hits|
      token, params, user_agent = tracker
      incs_from_params_and_user_agent(params, user_agent, hits).each do |inc, value|
        incs[token][inc] += value
      end
    end
    incs
  end

  def self.incs_from_params_and_user_agent(params, user_agent, hits)
    incs   = {}
    params = Addressable::URI.parse(params).query_values || {}
    if params.key?('e') && params.key?('h')
      case params['e']
      when 'l' # Player load &  Video prepare
        unless params.key?('po') # video prepare only
          if params.key?('em') # embed
            # Page Visits embeds
            incs['pv.em'] = hits
          else
            # Page Visits
            incs['pv.' + params['h']] = hits
            # Browser + Plateform
            if %w[m e].include?(params['h'])
              incs['bp.' + browser_and_platform_key(user_agent)] = hits
            end
          end
        end
        # Player Mode + Device hash
        if %w[m e].include?(params['h']) && params.key?('pm') && params.key?('d')
          params['pm'].uniq.each do |pm|
            incs['md.' + pm + '.' + params['d']] = params['pm'].count(pm) * hits
          end
        end
      when 's' # Video start (play)
        # Video Views
        incs['vv.' + params['h']] = hits
      end
    end
    incs
  end

  SUPPORTED_BROWSER = {
    "Firefox"           => "fir",
    "Chrome"            => "chr",
    "Internet Explorer" => "iex",
    "Safari"            => "saf",
    "Android"           => "and",
    "BlackBerry"        => "rim",
    "webOS"             => "weo",
    "Opera"             => "ope"
  }
  SUPPORTED_PLATFORM = {
    "Windows"       => "win",
    "Macintosh"     => "osx",
    "iPad"          => "ipa",
    "iPhone"        => "iph",
    "iPod"          => "ipo",
    "Linux"         => "lin",
    "Android"       => "and",
    "BlackBerry"    => "rim",
    "webOS"         => "weo",
    "Windows Phone" => "wip"
  }
  def self.browser_and_platform_key(user_agent)
    useragent    = UserAgent.parse(user_agent)
    browser_key  = SUPPORTED_BROWSER[useragent.browser] || "oth"
    platform_key = SUPPORTED_PLATFORM[useragent.platform] || (useragent.mobile? ? "otm" : "otd")
    browser_key + '-' + platform_key
  end

end
