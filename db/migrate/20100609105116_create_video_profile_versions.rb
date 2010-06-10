class CreateVideoProfileVersions < ActiveRecord::Migration
  def self.up
    create_table :video_profile_versions do |t|
      t.references :video_profile
      t.string :panda_profile_id
      t.text :note
      t.integer :num
      
      t.timestamps
    end
    
    add_index :video_profile_versions, :video_profile_id
  end
  
  def self.down
    drop_table :video_profile_versions
  end
end