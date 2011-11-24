class AddLast30DaysBillableVideoViewsArrayToSites < ActiveRecord::Migration
  def change
    add_column :sites, :last_30_days_billable_video_views_array, :text # serialized array
  end
end
