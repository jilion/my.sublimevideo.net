class CreateVideoProfiles < ActiveRecord::Migration
  def self.up
    create_table :video_profiles do |t|
      t.string  :title             # "iPhone WiFi"
      t.text    :description
      t.string  :name              # "iphone_wifi" IMMUABLE, can be blank
      t.string  :extname           # ".mp4"        IMMUABLE
      t.boolean :thumbnailable     # profile used to set the video thumbnail
      t.integer :versions_count, :default => 0
      
      t.timestamps
    end
  end
  
  def self.down
    drop_table :video_profiles
  end
end