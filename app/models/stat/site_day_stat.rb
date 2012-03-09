class Stat::SiteMinuteStat
  include Mongoid::Document
  include Stat::SiteStat
  store_in :site_minute_stats
end
