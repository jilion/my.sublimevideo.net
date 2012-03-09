module Stat::VideoStat
  extend ActiveSupport::Concern

  included do
    field :d,  type: DateTime  # Second / Minute / Hour / Day
    field :st, type: String # Site token
    field :u,  type: String # Video uid

    field :vl, type: Hash, default: {} # Video Loads: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2, em (embed) => 2 }
    field :vv, type: Hash, default: {} # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1, em (embed) => 2 }
    field :md, type: Hash, default: {} # Player Mode + Device { h (html5) => { d (desktop) => 2, m (mobile) => 1 }, f (flash) => ... }
    field :bp, type: Hash, default: {} # Browser + Plateform { "saf-win" => 2, "saf-osx" => 4, ...}
    field :vs, type: Hash, default: {} # Video Sources View { '5062d010' (video source crc32) => 32, ... }

    index :d
    index [[:st, Mongo::ASCENDING], [:u, Mongo::ASCENDING], [:d, Mongo::ASCENDING]]
    index [[:st, Mongo::ASCENDING], [:d, Mongo::ASCENDING]]
    
    scope "after".to_sym, lambda { |date| where(d: { "$gte" => date.to_i }) }
    scope "before".to_sym,  lambda { |date| where(d: { "$lte" => date.to_i }) }
    scope "between".to_sym, lambda { |start_date, end_date| where(d: { "$gte" => start_date.to_i, "$lte" => end_date.to_i }) }
  end

  # ====================
  # = Instance Methods =
  # ====================

  def time
    d.to_i
  end

  def site
    Site.find_by_token(st)
  end

  def site_token
    read_attribute(:st)
  end

  def uid
    read_attribute(:u)
  end

  # only main & extra hostname are counted in charts
  def chart_vv
    vv['m'].to_i + vv['e'].to_i
  end

end
