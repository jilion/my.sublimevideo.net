class RemoveUselessFieldsFromSites < ActiveRecord::Migration
  def self.up
    remove_column :sites, :loader_hits_cache
    remove_column :sites, :player_hits_cache
    remove_column :sites, :flash_hits_cache
    remove_column :sites, :requests_s3_cache
    remove_column :sites, :traffic_s3_cache
    remove_column :sites, :traffic_voxcast_cache
  end
  
  def self.down
  end
end
