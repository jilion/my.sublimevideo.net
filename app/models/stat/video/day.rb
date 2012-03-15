class Stat::Video::Day
  include Mongoid::Document
  include Stat::Video
  store_in :video_day_stats
  
  # Custom index for big top_videos query 
  index [[:st, Mongo::ASCENDING], [:d, Mongo::ASCENDING], [:vlc, Mongo::ASCENDING]]
end
