class SiteStat
  include Mongoid::Document

  field :t,  :type => String # Site token

  # DateTime periods
  field :m,  :type => DateTime  # Minute
  field :h,  :type => DateTime  # Hour
  field :d,  :type => DateTime  # Day

  field :pv, :type => Hash # Page Visits: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2 }
  field :vv, :type => Hash # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1 }
  field :md, :type => Hash # Player Mode + Device hash { h (html5) => { d (desktop) => 2, m (mobile) => 1 }, f (flash) => ... }
  field :bp, :type => Hash # Browser + Plateform hash { "saf-win" => 2, "saf-osx" => 4, ...}

  index :t
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

  %w[m h d].each do |period|
    scope "#{period}_after".to_sym, lambda { |date| where(period => { "$gte" => date }) }
    scope "#{period}_before".to_sym,  lambda { |date| where(period => { "$lt" => date }) }
    scope "#{period}_between".to_sym, lambda { |start_date, end_date| where(period => { "$gte" => start_date, "$lt" => end_date }) }
  end

  scope :last_data, lambda {
    where("$or" => [
      { m: { "$gte" => 60.minutes.ago.change(sec: 0).utc } },
      { h: { "$gte" => 24.hours.ago.change(min: 0, sec: 0).utc } },
      { d: { "$ne"  => nil } }
    ])
  }

  # ====================
  # = Instance Methods =
  # ====================

  %w[m h d].each do |period|
    define_method "#{period}i" do
      send(period).nil? ? nil : send(period).to_i * 1000
    end
  end

  # =================
  # = Class Methods =
  # =================

  def self.create_stats_from_trackers!(log, trackers)
    incs = incs_from_trackers(trackers)
    incs.each do |token, inc|
      self.collection.update({ t: token, m: log.minute }, { "$inc" => inc }, upsert: true)
      self.collection.update({ t: token, h: log.hour },   { "$inc" => inc }, upsert: true)
      self.collection.update({ t: token, d: log.day },    { "$inc" => inc }, upsert: true)
    end
  end

  def self.delay_clear_old_minutes_and_days_stats
    unless Delayed::Job.already_delayed?('%SiteStat%clear_old_minutes_and_days_stats%')
      delay(priority: 100, run_at: 15.minutes.from_now).clear_old_minutes_and_days_stats
    end
  end

  def self.clear_old_minutes_and_days_stats
    delay_clear_old_minutes_and_days_stats
    self.m_before(180.minutes.ago).delete_all
    self.h_before(72.hours.ago).delete_all
  end

private

  def self.incs_from_trackers(trackers)
    trackers = trackers.detect { |t| t.options[:title] == :stats }.categories
    incs     = Hash.new { |h,k| h[k] = Hash.new(0) }
    trackers.each do |tracker, hits|
      token, params, user_agent = tracker
      incs_from_params_and_user_agent(params, user_agent).each do |inc|
        incs[token][inc] += hits
      end
    end
    incs
  end

  def self.incs_from_params_and_user_agent(params, user_agent)
    incs   = []
    params = Addressable::URI.parse(params).query_values || {}
    if params.key?("e") && params.key?("h")
      case params["e"]
      when 'l' # Player load
        # Page Visits
        incs << 'pv.' + params["h"]
        # Browser + Plateform
        incs << 'bp.' + browser_and_platform_key(user_agent)
      when 'p' # Video prepare
        # Player Mode + Device hash
        if params.key?("pm") && params.key?("pd")
          incs << 'md.' + params["pm"] + '.' + params["pd"]
        end
      when 's' # Video start (play)
        # Video Views
        incs << 'vv.' + params["h"]
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