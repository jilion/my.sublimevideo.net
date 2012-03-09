class Stat::Site::Second
  include Mongoid::Document
  include Stat::Site
  store_in :site_second_stats
end
