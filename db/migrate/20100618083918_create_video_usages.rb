class CreateVideoUsages < ActiveRecord::Migration
  def self.up
    create_table :video_usages do |t|
      t.references :video
      t.references :log
      
      t.datetime  :started_at
      t.datetime  :ended_at
      
      t.integer   :hits,      default: 0
      
      t.integer   :bandwidth_s3, default: 0 # S3
      t.integer   :bandwidth_us, default: 0 # United States
      t.integer   :bandwidth_eu, default: 0 # European
      t.integer   :bandwidth_as, default: 0 # Asia (Hong Kong & Singapore)
      t.integer   :bandwidth_jp, default: 0 # Japan (Tokyo)
      t.integer   :bandwidth_unknown, default: 0 # Cloudfront unknown location
      
      t.integer   :requests_s3, default: 0 # S3
      t.integer   :requests_us, default: 0 # United States
      t.integer   :requests_eu, default: 0 # European
      t.integer   :requests_as, default: 0 # Asia (Hong Kong & Singapore)
      t.integer   :requests_jp, default: 0 # Japan (Tokyo)
      t.integer   :requests_unknown, default: 0 # Cloudfront unknown location
      
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
