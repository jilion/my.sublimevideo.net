class Stat::SiteSecondStat
  include Mongoid::Document
  include Stat::SiteStat
  store_in :site_second_stats
end
