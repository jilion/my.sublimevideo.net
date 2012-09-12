# encoding: utf-8

class Stat::Site::Day
  include Mongoid::Document
  include Stat::Site

  store_in collection: 'site_day_stats'
end
