class AddBandwidthAndRequestsCacheToSites < ActiveRecord::Migration
  def self.up
    add_column :sites, :requests_s3_cache,       :integer, default: 0
    add_column :sites, :bandwidth_s3_cache,      :integer, default: 0
    add_column :sites, :bandwidth_voxcast_cache, :integer, default: 0
  end
  
  def self.down
    remove_column :sites, :requests_s3_cache
    remove_column :sites, :bandwidth_s3_cache
    remove_column :sites, :bandwidth_voxcast_cache
  end
end
