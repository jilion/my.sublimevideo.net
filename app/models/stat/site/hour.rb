# encoding: utf-8

class Stat::Site::Hour
  include Mongoid::Document
  include Stat::Site

  store_in collection: 'site_hour_stats'
end
