class CreateVideoUsages < ActiveRecord::Migration
  def self.up
    create_table :video_usages do |t|
      t.integer :video_id
      t.integer :log_id
      t.datetime :started_at
      t.datetime :ended_at
      t.integer :bandwidth

      t.timestamps
    end
  end

  def self.down
    drop_table :video_usages
  end
end
