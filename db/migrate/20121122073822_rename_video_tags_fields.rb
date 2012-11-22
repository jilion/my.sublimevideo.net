class RenameVideoTagsFields < ActiveRecord::Migration
  def change
    rename_column :video_tags, :video_id, :sources_id
    rename_column :video_tags, :video_id_origin, :sources_origin
  end
end
