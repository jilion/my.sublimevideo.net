class CreateSiteUsages < ActiveRecord::Migration
  def self.up
    create_table :site_usages do |t|
      t.integer   :site_id
      t.integer   :log_id
      t.datetime  :started_at
      t.datetime  :ended_at
      t.integer   :license_hits
      t.integer   :js_hits
      t.integer   :flash_hits
      
      t.timestamps
    end
  end
  
  def self.down
    drop_table :site_usages
  end
end
