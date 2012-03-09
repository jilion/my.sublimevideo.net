class Stat::TopVideoMinuteStat
  include Mongoid::Document
  include Stat::TopVideoStat
  store_in :top_video_minute_stats
end
