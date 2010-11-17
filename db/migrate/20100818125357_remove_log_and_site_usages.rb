class RemoveLogAndSiteUsages < ActiveRecord::Migration
  def self.up
    remove_index :logs, [:type, :name]
    remove_index :logs, [:type, :started_at]
    remove_index :logs, [:type, :ended_at]
    drop_table :logs
    
    remove_index :site_usages, :started_at
    remove_index :site_usages, :site_id
    remove_index :site_usages, :ended_at
    drop_table :site_usages
  end
  
  def self.down
    # Sorry no way back!
  end
end
