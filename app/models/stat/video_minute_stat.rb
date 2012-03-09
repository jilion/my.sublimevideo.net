class Stat::VideoMinuteStat
  include Mongoid::Document
  include Stat::VideoStat
  store_in :video_minute_stats
end
