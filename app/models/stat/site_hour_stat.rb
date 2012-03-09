class Stat::SiteHourStat
  include Mongoid::Document
  include Stat::SiteStat
  store_in :site_hour_stats
end
