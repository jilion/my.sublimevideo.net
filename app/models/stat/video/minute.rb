# encoding: utf-8

class Stat::Video::Minute
  include Mongoid::Document
  include Stat::Video

  store_in collection: 'video_minute_stats'

  index st: 1, d: 1
end
