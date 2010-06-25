class RenameThumbnailToPosterframeInVideos < ActiveRecord::Migration
  def self.up
    rename_column :videos, :thumbnail, :posterframe
  end
  
  def self.down
    rename_column :videos, :posterframe, :thumbnail
  end
end