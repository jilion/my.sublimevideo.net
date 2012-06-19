class CreateVideoProfiles < ActiveRecord::Migration
  def self.up
    create_table :video_profiles do |t|
      t.string  :title             # "iPhone WiFi"
      t.text    :description
      t.string  :name              # "_iphone_wifi"
      t.string  :extname           # "mp4"
      t.boolean :thumbnailable     # profile used to set the video thumbnail
      t.integer :min_width         # minimum required width to fire this profile when encoding a video
      t.integer :min_height        # minimum required height to fire this profile when encoding a video
      t.integer :versions_count, default: 0
      
      t.timestamps
    end
  end
  
  def self.down
    drop_table :video_profiles
  end
end