class RemoveVideo < ActiveRecord::Migration
  def self.up
    drop_table :videos
    remove_index :videos, :user_id
    remove_index :videos, :title
    remove_index :videos, :token
    remove_index :videos, :hits_cache
    remove_index :videos, :created_at
    
    remove_column :invoices, :videos_amount
    remove_column :invoices, :videos
    
    drop_table :video_profiles
    drop_table :video_profile_versions
    remove_index :video_profile_versions, :video_profile_id
    drop_table :video_encodings
    drop_table :video_usages
    remove_index :video_usages, :video_id
    remove_index :video_usages, :started_at
    remove_index :video_usages, :ended_at
  end
  
  def self.down
    # Sorry no way back!
  end
end
