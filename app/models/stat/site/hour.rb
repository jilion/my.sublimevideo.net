class Stat::Site::Hour
  include Mongoid::Document
  include Stat::Site
  store_in :site_hour_stats
end
