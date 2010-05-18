class CreateVideos < ActiveRecord::Migration
  def self.up
    create_table :videos do |t|
      t.integer :user_id
      t.integer :original_id, :null => true, :default => nil
      t.string :name
      t.string :token
      t.string :file
      t.string :thumbnail
      t.integer :size
      t.integer :duration
      t.string  :state
      t.string :type
      t.timestamps
    end
  end

  def self.down
    drop_table :videos
  end
end
