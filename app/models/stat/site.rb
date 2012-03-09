# =================================================================
# = OLD Class, will be removed. Please use Stat::SiteStat instead =
# =================================================================

class Stat::Site
  include Mongoid::Document
  include Stat
  store_in :site_stats

  field :t, type: String # Site token

  field :pv, type: Hash, default: {} # Page Visits: { m (main) => 2, e (extra) => 10, d (dev) => 43, i (invalid) => 2, em (embed) => 2 }
  field :vv, type: Hash, default: {} # Video Views: { m (main) => 1, e (extra) => 3, d (dev) => 11, i (invalid) => 1, em (embed) => 2 }
  field :md, type: Hash, default: {} # Player Mode + Device { h (html5) => { d (desktop) => 2, m (mobile) => 1 }, f (flash) => ... }
  field :bp, type: Hash, default: {} # Browser + Plateform { "saf-win" => 2, "saf-osx" => 4, ...}

  index :d # for Stats::SiteStatsStat#create_site_stats_stat
  index :h
  index :m
  index :s
  index [[:t, Mongo::ASCENDING], [:s, Mongo::ASCENDING]]
  index [[:t, Mongo::ASCENDING], [:m, Mongo::ASCENDING]]
  index [[:t, Mongo::ASCENDING], [:h, Mongo::ASCENDING]]
  index [[:t, Mongo::ASCENDING], [:d, Mongo::ASCENDING]]

end
