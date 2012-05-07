class AddLast30DaysVideoTagsToSite < ActiveRecord::Migration
  def change
    add_column :sites, :last_30_days_video_tags, :integer, :default => 0
  end
end
