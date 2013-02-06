class ChangeSiteTokenToVideoTags < ActiveRecord::Migration
  def change
    change_column :video_tags, :site_token, :string, null: false
  end
end
