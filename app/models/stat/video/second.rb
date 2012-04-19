# encoding: utf-8

class Stat::Video::Second
  include Mongoid::Document
  include Stat::Video
  store_in :video_second_stats
  
  index [[:st, Mongo::ASCENDING], [:d, Mongo::ASCENDING]]
end
