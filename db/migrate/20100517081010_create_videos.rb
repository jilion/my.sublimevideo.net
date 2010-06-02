class CreateVideos < ActiveRecord::Migration
  def self.up
    create_table :videos do |t|
      t.references :user
      t.integer :original_id, :null => true, :default => nil
      t.string  :panda_id
      
      t.string  :name
      t.string  :token
      t.string  :file
      t.string  :thumbnail
      t.string  :codec
      t.string  :container
      t.integer :size
      t.integer :duration
      t.integer :width
      t.integer :height
      t.string  :state
      t.string  :type
      t.timestamps
    end
    
    add_index :videos, :user_id
    add_index :videos, :name
    add_index :videos, :created_at
    add_index :videos, :original_id
  end
  
  def self.down
    drop_table :videos
  end
end
