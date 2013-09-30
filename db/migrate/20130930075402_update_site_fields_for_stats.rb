class UpdateSiteFieldsForStats < ActiveRecord::Migration
  def change
    remove_index :sites, :last_30_days_dev_video_views
    remove_index :sites, :last_30_days_embed_video_views
    remove_index :sites, :last_30_days_extra_video_views
    remove_index :sites, :last_30_days_invalid_video_views
    remove_index :sites, :last_30_days_main_video_views

    remove_column :sites, :last_30_days_billable_video_views_array
    remove_column :sites, :last_30_days_dev_video_views
    remove_column :sites, :last_30_days_embed_video_views
    remove_column :sites, :last_30_days_extra_video_views
    remove_column :sites, :last_30_days_invalid_video_views
    remove_column :sites, :last_30_days_main_video_views

    rename_column :sites, :first_billable_plays_at, :first_admin_starts_on

    add_column :sites, :last_30_days_starts, :integer, default: 0
    add_column :sites, :last_30_days_starts_array, :integer, array: true, default: []
    add_column :sites, :last_30_days_admin_starts, :integer, default: 0

    add_index :sites, [:user_id, :last_30_days_starts]
    add_index :sites, :last_30_days_admin_starts
    add_index :sites, :first_admin_starts_on
  end
end
