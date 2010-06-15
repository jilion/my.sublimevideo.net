class CreateVideoEncodings < ActiveRecord::Migration
  def self.up
    create_table :video_encodings do |t|
      t.references :video
      t.references :video_profile_version
      
      t.string     :state                   # state machine
      t.string     :file                    # carrierwave
      
      # Panda fields
      t.string     :panda_encoding_id
      t.datetime   :started_encoding_at
      t.integer    :encoding_time
      t.string     :extname
      t.integer    :file_size
      t.integer    :width
      t.integer    :height
      
      t.timestamps
    end
  end
  
  def self.down
    drop_table :video_encodings
  end
end