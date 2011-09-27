class SiteStat
  include Mongoid::Document

  field :t,  :type => String # Site token

  # DateTime periods
  field :s,  :type => DateTime  # Second
  field :m,  :type => DateTime  # Minute
  field :h,  :type => DateTime  # Hour
  field :d,  :type => DateTime  # Day

  field :pv, :type => Hash # Page Visits: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2 }
  field :vv, :type => Hash # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1 }
  field :md, :type => Hash # Player Mode + Device hash { h (html5) => { d (desktop) => 2, m (mobile) => 1 }, f (flash) => ... }
  field :bp, :type => Hash # Browser + Plateform hash { "saf-win" => 2, "saf-osx" => 4, ...}

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
  def t
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

  def self.json(token, period_type = 'days')
    stats      = SiteStat.where(t: token)
    json_stats = []
    case period_type
    when 'seconds'
      to    = 1.second.ago.change(usec: 0).utc
      from  = to - 59.seconds
      stats = stats.s_after(from).entries
      while from <= to
        if stats.first.try(:s) == from
          json_stats << stats.shift
        else
          json_stats << SiteStat.new(s: from.to_time)
        end
        from += 1.second
      end
    when 'minutes'
      to    = SiteStat.where(m: { "$ne"  => nil }).order_by([:m, :asc]).last.m
      from  = to - 59.minutes
      stats = stats.m_after(from).entries
      while from <= to
        if stats.first.try(:m) == from
          json_stats << stats.shift
        else
          json_stats << SiteStat.new(m: from.to_time)
        end
        from += 1.minute
      end
    when 'hours'
      to    = 1.hour.ago.change(min: 0, sec: 0).utc
      from  = to - 23.hours
      stats = stats.h_after(from).entries
      while from <= to
        if stats.first.try(:h) == from
          json_stats << stats.shift
        else
          json_stats << SiteStat.new(h: from.to_time)
        end
        from += 1.hour
      end
    when 'days'
      stats = stats.where(d: { "$ne" => nil }).order_by([:d, :asc]).entries
      to    = 1.day.ago.change(hour: 0, min: 0, sec: 0).utc
      from  = [(stats.first.try(:d) || Time.now.utc), to - 29.days].min
      while from <= to
        if stats.first.try(:d) == from
          json_stats << stats.shift
        else
          json_stats << SiteStat.new(d: from.to_time)
        end
        from += 1.day
      end
    end

    json_stats.to_json(except: [:_id, :t, :s, :m, :h, :d], methods: [:t])
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
        incs['bp.' + browser_and_platform_key(user_agent)] = hits
      when 'p' # Video prepare
        # Player Mode + Device hash
        if params.key?("pm") && params.key?("pd")
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
