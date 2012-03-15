class Stat::Video::Minute
  include Mongoid::Document
  include Stat::Video
  store_in :video_minute_stats
  
  index [[:st, Mongo::ASCENDING], [:d, Mongo::ASCENDING]]
end
