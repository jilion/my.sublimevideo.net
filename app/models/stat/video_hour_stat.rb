class Stat::VideoHourStat
  include Mongoid::Document
  include Stat::VideoStat
  store_in :video_hour_stats
end
