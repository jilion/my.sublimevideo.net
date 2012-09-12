# encoding: utf-8

class Stat::Video::Day
  include Mongoid::Document
  include Stat::Video

  store_in collection: 'video_day_stats'

  # Custom index for big top_videos query
  index st: 1, d: 1, vlc: 1
end
