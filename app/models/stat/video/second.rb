# encoding: utf-8

class Stat::Video::Second
  include Mongoid::Document
  include Stat::Video

  store_in collection: 'video_second_stats'

  index st: 1, d: 1
end
