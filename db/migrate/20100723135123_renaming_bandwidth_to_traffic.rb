class RenamingBandwidthToTraffic < ActiveRecord::Migration
  def self.up
    rename_column :site_usages, :bandwidth_s3, :traffic_s3
    rename_column :site_usages, :bandwidth_voxcast, :traffic_voxcast
    
    rename_column :sites, :bandwidth_s3_cache, :traffic_s3_cache
    rename_column :sites, :bandwidth_voxcast_cache, :traffic_voxcast_cache
    
    rename_column :video_usages, :bandwidth_s3, :traffic_s3
    rename_column :video_usages, :bandwidth_us, :traffic_us
    rename_column :video_usages, :bandwidth_eu, :traffic_eu
    rename_column :video_usages, :bandwidth_as, :traffic_as
    rename_column :video_usages, :bandwidth_jp, :traffic_jp
    rename_column :video_usages, :bandwidth_unknown, :traffic_unknown
    
    rename_column :videos, :bandwidth_s3_cache, :traffic_s3_cache
    rename_column :videos, :bandwidth_us_cache, :traffic_us_cache
    rename_column :videos, :bandwidth_eu_cache, :traffic_eu_cache
    rename_column :videos, :bandwidth_as_cache, :traffic_as_cache
    rename_column :videos, :bandwidth_jp_cache, :traffic_jp_cache
    rename_column :videos, :bandwidth_unknown_cache, :traffic_unknown_cache
  end

  def self.down
    rename_column :videos, :traffic_unknown_cache, :bandwidth_unknown_cache
    rename_column :videos, :traffic_jp_cache, :bandwidth_jp_cache
    rename_column :videos, :traffic_as_cache, :bandwidth_as_cache
    rename_column :videos, :traffic_eu_cache, :bandwidth_eu_cache
    rename_column :videos, :traffic_us_cache, :bandwidth_us_cache
    rename_column :videos, :traffic_s3_cache, :bandwidth_s3_cache
    
    rename_column :video_usages, :traffic_unknown, :bandwidth_unknown
    rename_column :video_usages, :traffic_jp, :bandwidth_jp
    rename_column :video_usages, :traffic_as, :bandwidth_as
    rename_column :video_usages, :traffic_eu, :bandwidth_eu
    rename_column :video_usages, :traffic_us, :bandwidth_us
    rename_column :video_usages, :traffic_s3, :bandwidth_s3
    
    rename_column :sites, :traffic_voxcast_cache, :bandwidth_voxcast_cache
    rename_column :sites, :traffic_s3_cache, :bandwidth_s3_cache
    
    rename_column :site_usages, :traffic_voxcast, :bandwidth_voxcast
    rename_column :site_usages, :traffic_s3, :bandwidth_s3
  end
end