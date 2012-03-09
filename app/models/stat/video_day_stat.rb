class Stat::VideoDayStat
  include Mongoid::Document
  include Stat::VideoStat
  store_in :video_day_stats
end
