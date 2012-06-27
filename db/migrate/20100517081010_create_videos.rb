class CreateVideos < ActiveRecord::Migration
  def self.up
    create_table :videos do |t|
      t.references :user
      
      t.string     :title
      t.string     :token     # uniquify
      t.string     :state     # state machine
      t.string     :thumbnail # carrierwave
                   
      t.integer    :hits_cache, default: 0
      t.integer    :bandwidth_s3_cache, default: 0
      t.integer    :bandwidth_us_cache, default: 0
      t.integer    :bandwidth_eu_cache, default: 0
      t.integer    :bandwidth_as_cache, default: 0
      t.integer    :bandwidth_jp_cache, default: 0
      t.integer    :bandwidth_unknown_cache, default: 0
      t.integer    :requests_s3_cache, default: 0
      t.integer    :requests_us_cache, default: 0
      t.integer    :requests_eu_cache, default: 0
      t.integer    :requests_as_cache, default: 0
      t.integer    :requests_jp_cache, default: 0
      t.integer    :requests_unknown_cache, default: 0
      
      # Panda fields
      t.string     :panda_video_id
      t.string     :original_filename
      t.string     :video_codec
      t.string     :audio_codec
      t.string     :extname
      t.integer    :file_size
      t.integer    :duration
      t.integer    :width
      t.integer    :height
      t.integer    :fps
      
      t.datetime   :archived_at
      t.timestamps
    end
    
    add_index :videos, :user_id
    add_index :videos, :title
    add_index :videos, :token
    add_index :videos, :hits_cache
    add_index :videos, :created_at
  end
  
  def self.down
    drop_table :videos
  end
end