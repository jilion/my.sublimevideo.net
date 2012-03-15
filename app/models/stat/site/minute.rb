class Stat::Site::Minute
  include Mongoid::Document
  include Stat::Site
  store_in :site_minute_stats
end
