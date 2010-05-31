class CreateSiteUsages < ActiveRecord::Migration
  def self.up
    create_table :site_usages do |t|
      t.integer   :site_id
      t.integer   :log_id
      t.datetime  :started_at
      t.datetime  :ended_at
      
      t.integer   :loader_hits, :default => 0
      t.integer   :js_hits,     :default => 0
      t.integer   :flash_hits,  :default => 0
      
      t.timestamps
    end
    
    add_index :site_usages, :site_id
    add_index :site_usages, :started_at
    add_index :site_usages, :ended_at
  end
  
  def self.down
    drop_table :site_usages
  end
end
