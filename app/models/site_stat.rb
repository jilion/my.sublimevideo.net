class SiteStat
  include Mongoid::Document

  field :t,  :type => String # Site token

  field :m,  :type => DateTime  # Minute
  field :h,  :type => DateTime  # Hour
  field :d,  :type => DateTime  # Day

  field :pv, :type => Hash # Page Visits: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2 }
  field :vv, :type => Hash # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1 }
  field :md, :type => Hash # Player Mode + Device hash { h (html5) => { d (desktop) => 2, m (mobile) => 1 }, f (flash) => ... }
  field :po, :type => Hash # Platform + OS { "saf-win" => 2, "saf-osx" => 4, ...}

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

  # =================
  # = Class Methods =
  # =================

  def self.create_stats_from_trackers!(log, trackers)

  end

end