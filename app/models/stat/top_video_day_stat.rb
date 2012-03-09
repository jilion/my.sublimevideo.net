class Stat::TopVideoDayStat
  include Mongoid::Document
  include Stat::TopVideoStat
  store_in :top_video_day_stats
  
  # Custom index for big top_videos query
  index [[:st, Mongo::ASCENDING], [:d, Mongo::ASCENDING], [:vl, Mongo::ASCENDING]]
end
