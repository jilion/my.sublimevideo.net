# encoding: utf-8

class Stat::Site::Second
  include Mongoid::Document
  include Stat::Site

  store_in collection: 'site_second_stats'
end
