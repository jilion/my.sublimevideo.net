class SiteStat
  include Mongoid::Document

  field :t,  type: String # Site token

  # DateTime periods
  field :s,  type: DateTime  # Second
  field :m,  type: DateTime  # Minute
  field :h,  type: DateTime  # Hour
  field :d,  type: DateTime  # Day

  field :pv, type: Hash, default: {} # Page Visits: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2 }
  field :vv, type: Hash, default: {} # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1 }
  field :md, type: Hash              # Player Mode + Device hash { h (html5) => { d (desktop) => 2, m (mobile) => 1 }, f (flash) => ... }
  field :bp, type: Hash              # Browser + Plateform hash { "saf-win" => 2, "saf-osx" => 4, ...}

  index :t
  index [[:t, Mongo::ASCENDING], [:s, Mongo::ASCENDING]]#, :unique => true
  index [[:t, Mongo::ASCENDING], [:m, Mongo::ASCENDING]]#, :unique => true
  index [[:t, Mongo::ASCENDING], [:h, Mongo::ASCENDING]]#, :unique => true
  index [[:t, Mongo::ASCENDING], [:d, Mongo::ASCENDING]]#, :unique => true

  # ================
  # = Associations =
  # ================

  def site
    Site.find_by_token(t)
  end

  # ==========
  # = Scopes =
  # ==========

  %w[s m h d].each do |period|
    scope "#{period}_after".to_sym, lambda { |date| where(period => { "$gte" => date.to_i }).order_by([period.to_sym, :asc]) }
    scope "#{period}_before".to_sym,  lambda { |date| where(period => { "$lt" => date.to_i }).order_by([period.to_sym, :asc]) }
    scope "#{period}_between".to_sym, lambda { |start_date, end_date| where(period => { "$gte" => start_date.to_i, "$lt" => end_date.to_i }).order_by([period.to_sym, :asc]) }
  end

  # ====================
  # = Instance Methods =
  # ====================

  def token
    read_attribute(:t)
  end

  # time for backbonejs model
  def id
    (s || m || h || d).to_i
  end

  # only main & extra hostname are counted in charts
  def pv
    pv = read_attribute(:pv)
    pv['m'].to_i + pv['e'].to_i
  end

  def vv
    vv = read_attribute(:vv)
    vv['m'].to_i + vv['e'].to_i
  end

  # =================
  # = Class Methods =
  # =================

  def self.last_stats(token_or_stats, from, to, period_type, options = {})
    options.reverse_merge!(fill_missing_days: true)

    token_or_stats = self.where(t: token_or_stats) if token_or_stats.is_a? String
    stats          = token_or_stats.send("#{period_type[0]}_between", from, to + 1.send(period_type)).entries

    if !!options[:fill_missing_days]
      filled_stats = []
      missing_days_value = options[:fill_missing_days].respond_to?(:to_i) ? options[:fill_missing_days].to_i : 0
      while from <= to
        filled_stats << if stats.first.try(period_type[0]) == from
          stats.shift
        else
          self.new(period_type[0].to_sym => from.to_time, pv: { 'm' => missing_days_value })
        end
        from += 1.send(period_type)
      end
      filled_stats
    else
      stats
    end
  end

  def self.last_days(token, options = {})
    options.reverse_merge!(days: 30)

    last_stats(token, options[:days].days.ago.midnight, 1.day.ago.midnight, 'days', options)
  end

  def self.json(token, period_type = 'days')
    stats      = self.where(t: token)
    json_stats = case period_type
    when 'seconds'
      to   = 1.second.ago.change(usec: 0).utc
      from = to - 59.seconds

      last_stats(stats, from, to, period_type)

    when 'minutes'
      to   = self.where(m: { "$ne" => nil }).order_by([:m, :asc]).last.m
      from = to - 59.minutes

      last_stats(stats, from, to, period_type)

    when 'hours'
      to   = 1.hour.ago.change(min: 0, sec: 0).utc
      from = to - 23.hours

      last_stats(stats, from, to, period_type)

    when 'days'
      stats = stats.where(d: { "$ne" => nil }).order_by([:d, :asc])
      to    = 1.day.ago.midnight
      from  = [(stats.first.try(:d) || Time.now.utc), to - 29.days].min

      last_stats(stats, from, to, period_type)
    end

    json_stats.to_json(except: [:_id, :t, :s, :m, :h, :d], methods: [:id])
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

  def self.delay_clear_old_minutes_and_days_stats
    unless Delayed::Job.already_delayed?('%SiteStat%clear_old_minutes_and_days_stats%')
      delay(priority: 100, run_at: 5.minutes.from_now).clear_old_minutes_and_days_stats
    end
  end

  def self.clear_old_minutes_and_days_stats
    delay_clear_old_minutes_and_days_stats
    self.s_before(90.seconds.ago).delete_all
    self.m_before(180.minutes.ago).delete_all
    self.h_before(72.hours.ago).delete_all
  end

private

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
    if params.key?("e") && params.key?("h")
      case params["e"]
      when 'l' # Player load
        # Page Visits
        incs['pv.' + params["h"]] = hits
        # Browser + Plateform
        if %w[m e].include?(params["h"])
          incs['bp.' + browser_and_platform_key(user_agent)] = hits
        end
      when 'p' # Video prepare
        # Player Mode + Device hash
        if %w[m e].include?(params["h"]) && params.key?("pm") && params.key?("pd")
          params["pm"].uniq.each do |pm|
            incs['md.' + pm + '.' + params["pd"]] = params['pm'].count(pm) * hits
          end
        end
      when 's' # Video start (play)
        # Video Views
        incs['vv.' + params["h"]] = hits
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
  SUPPORTED_PLATEFORM = {
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
    platform_key = SUPPORTED_PLATEFORM[useragent.platform] || (useragent.mobile? ? "otm" : "otd")
    browser_key + '-' + platform_key
  end

end
