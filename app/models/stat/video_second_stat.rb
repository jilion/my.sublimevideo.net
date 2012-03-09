class Stat::VideoSecondStat
  include Mongoid::Document
  include Stat::VideoStat
  store_in :video_second_stats
end
