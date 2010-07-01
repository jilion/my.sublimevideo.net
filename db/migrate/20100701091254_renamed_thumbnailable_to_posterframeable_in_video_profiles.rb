class RenamedThumbnailableToPosterframeableInVideoProfiles < ActiveRecord::Migration
  def self.up
    rename_column :video_profiles, :thumbnailable, :posterframeable
  end
  
  def self.down
    rename_column :video_profiles, :posterframeable, :thumbnailable
  end
end