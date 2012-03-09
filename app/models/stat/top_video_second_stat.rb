class Stat::TopVideoSecondStat
  include Mongoid::Document
  include Stat::TopVideoStat
  store_in :top_video_second_stats
end
