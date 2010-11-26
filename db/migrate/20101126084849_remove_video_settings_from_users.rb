class RemoveVideoSettingsFromUsers < ActiveRecord::Migration
  def self.up
    remove_column :users, :video_settings
  end
  
  def self.down
    add_column :users, :video_settings, :text
  end
end
