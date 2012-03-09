class Stat::SiteDayStat
  include Mongoid::Document
  include Stat::SiteStat
  store_in :site_day_stats
end
