class RemoveVideo < ActiveRecord::Migration
  def self.up
    remove_index :videos, :user_id
    remove_index :videos, :title
    remove_index :videos, :token
    remove_index :videos, :hits_cache
    remove_index :videos, :created_at
    drop_table :videos
    
    remove_column :invoices, :videos_amount
    remove_column :invoices, :videos
    
    remove_index :video_profile_versions, :video_profile_id
    remove_index :video_usages, :video_id
    remove_index :video_usages, :started_at
    remove_index :video_usages, :ended_at
    
    drop_table :video_profiles
    drop_table :video_profile_versions
    drop_table :video_encodings
    drop_table :video_usages
  end
  
  def self.down
    # Sorry no way back!
  end
end
