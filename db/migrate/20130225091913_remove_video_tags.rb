class RemoveVideoTags < ActiveRecord::Migration
  def up
    remove_index :video_tags, [:site_id, :uid]
    remove_index :video_tags, [:site_id, :updated_at]

    drop_table :video_tags
  end

  def down
  end
end
