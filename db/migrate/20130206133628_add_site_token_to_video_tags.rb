class AddSiteTokenToVideoTags < ActiveRecord::Migration
  def change
    add_column :video_tags, :site_token, :string
  end
end
