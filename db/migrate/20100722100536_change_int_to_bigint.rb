class ChangeIntToBigint < ActiveRecord::Migration
  def self.up
    change_column(:invoices, :amount,                :bigint)
    change_column(:invoices, :sites_amount,          :bigint)
    change_column(:invoices, :videos_amount,         :bigint)
    
    change_column(:sites, :loader_hits_cache,        :bigint)
    change_column(:sites, :player_hits_cache,        :bigint)
    change_column(:sites, :flash_hits_cache,         :bigint)
    change_column(:sites, :requests_s3_cache,        :bigint)
    change_column(:sites, :bandwidth_s3_cache,       :bigint)
    change_column(:sites, :bandwidth_voxcast_cache,  :bigint)
    
    change_column(:site_usages, :loader_hits,        :bigint)
    change_column(:site_usages, :player_hits,        :bigint)
    change_column(:site_usages, :flash_hits,         :bigint)
    change_column(:site_usages, :requests_s3,        :bigint)
    change_column(:site_usages, :bandwidth_s3,       :bigint)
    change_column(:site_usages, :bandwidth_voxcast,  :bigint)
    
    change_column(:videos, :hits_cache,              :bigint)
    change_column(:videos, :bandwidth_s3_cache,      :bigint)
    change_column(:videos, :bandwidth_us_cache,      :bigint)
    change_column(:videos, :bandwidth_eu_cache,      :bigint)
    change_column(:videos, :bandwidth_as_cache,      :bigint)
    change_column(:videos, :bandwidth_jp_cache,      :bigint)
    change_column(:videos, :bandwidth_unknown_cache, :bigint)
    change_column(:videos, :requests_s3_cache,       :bigint)
    change_column(:videos, :requests_us_cache,       :bigint)
    change_column(:videos, :requests_eu_cache,       :bigint)
    change_column(:videos, :requests_as_cache,       :bigint)
    change_column(:videos, :requests_jp_cache,       :bigint)
    change_column(:videos, :requests_unknown_cache,  :bigint)
    
    change_column(:video_usages, :hits,              :bigint)
    change_column(:video_usages, :bandwidth_s3,      :bigint)
    change_column(:video_usages, :bandwidth_us,      :bigint)
    change_column(:video_usages, :bandwidth_eu,      :bigint)
    change_column(:video_usages, :bandwidth_as,      :bigint)
    change_column(:video_usages, :bandwidth_jp,      :bigint)
    change_column(:video_usages, :bandwidth_unknown, :bigint)
    change_column(:video_usages, :requests_s3,       :bigint)
    change_column(:video_usages, :requests_us,       :bigint)
    change_column(:video_usages, :requests_eu,       :bigint)
    change_column(:video_usages, :requests_as,       :bigint)
    change_column(:video_usages, :requests_jp,       :bigint)
    change_column(:video_usages, :requests_unknown,  :bigint)
  end
  
  def self.down
    change_column(:invoices, :amount,                :integer)
    change_column(:invoices, :sites_amount,          :integer)
    change_column(:invoices, :videos_amount,         :integer)
    
    change_column(:sites, :loader_hits_cache,        :integer)
    change_column(:sites, :player_hits_cache,        :integer)
    change_column(:sites, :flash_hits_cache,         :integer)
    change_column(:sites, :requests_s3_cache,        :integer)
    change_column(:sites, :bandwidth_s3_cache,       :integer)
    change_column(:sites, :bandwidth_voxcast_cache,  :integer)
    
    change_column(:site_usages, :loader_hits,        :integer)
    change_column(:site_usages, :player_hits,        :integer)
    change_column(:site_usages, :flash_hits,         :integer)
    change_column(:site_usages, :requests_s3,        :integer)
    change_column(:site_usages, :bandwidth_s3,       :integer)
    change_column(:site_usages, :bandwidth_voxcast,  :integer)
    
    change_column(:videos, :hits_cache,              :integer)
    change_column(:videos, :bandwidth_s3_cache,      :integer)
    change_column(:videos, :bandwidth_us_cache,      :integer)
    change_column(:videos, :bandwidth_eu_cache,      :integer)
    change_column(:videos, :bandwidth_as_cache,      :integer)
    change_column(:videos, :bandwidth_jp_cache,      :integer)
    change_column(:videos, :bandwidth_unknown_cache, :integer)
    change_column(:videos, :requests_s3_cache,       :integer)
    change_column(:videos, :requests_us_cache,       :integer)
    change_column(:videos, :requests_eu_cache,       :integer)
    change_column(:videos, :requests_as_cache,       :integer)
    change_column(:videos, :requests_jp_cache,       :integer)
    change_column(:videos, :requests_unknown_cache,  :integer)
    
    change_column(:video_usages, :hits,              :integer)
    change_column(:video_usages, :bandwidth_s3,      :integer)
    change_column(:video_usages, :bandwidth_us,      :integer)
    change_column(:video_usages, :bandwidth_eu,      :integer)
    change_column(:video_usages, :bandwidth_as,      :integer)
    change_column(:video_usages, :bandwidth_jp,      :integer)
    change_column(:video_usages, :bandwidth_unknown, :integer)
    change_column(:video_usages, :requests_s3,       :integer)
    change_column(:video_usages, :requests_us,       :integer)
    change_column(:video_usages, :requests_eu,       :integer)
    change_column(:video_usages, :requests_as,       :integer)
    change_column(:video_usages, :requests_jp,       :integer)
    change_column(:video_usages, :requests_unknown,  :integer)
  end
end