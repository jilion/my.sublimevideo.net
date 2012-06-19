class AddBandwidthAndRequestsToSiteUsages < ActiveRecord::Migration
  def self.up
    add_column :site_usages, :requests_s3,       :integer, default: 0
    add_column :site_usages, :bandwidth_s3,      :integer, default: 0
    add_column :site_usages, :bandwidth_voxcast, :integer, default: 0
  end
  
  def self.down
    remove_column :site_usages, :requests_s3
    remove_column :site_usages, :bandwidth_s3
    remove_column :site_usages, :bandwidth_voxcast
  end
end
