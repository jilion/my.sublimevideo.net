class CreateVideoUsages < ActiveRecord::Migration
  def self.up
    create_table :video_usages do |t|
      t.references :video
      t.references :log
      
      t.datetime  :started_at
      t.datetime  :ended_at
      
      t.integer   :hits,      :default => 0
      t.integer   :bandwidth, :default => 0
      
      t.timestamps
    end
    
    add_index :video_usages, :video_id
    add_index :video_usages, :started_at
    add_index :video_usages, :ended_at
  end
  
  def self.down
    drop_table :video_usages
  end
end
