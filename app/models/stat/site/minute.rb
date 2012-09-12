# encoding: utf-8

class Stat::Site::Minute
  include Mongoid::Document
  include Stat::Site

  store_in collection: 'site_minute_stats'
end
