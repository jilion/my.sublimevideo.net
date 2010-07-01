class AddFileAddedAtAndFileRemovedAtToVideoEncodings < ActiveRecord::Migration
  def self.up
    add_column :video_encodings, :file_added_at, :datetime
    add_column :video_encodings, :file_removed_at, :datetime
  end
  
  def self.down
    remove_column :video_encodings, :file_removed_at
    remove_column :video_encodings, :file_added_at
  end
end