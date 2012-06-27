class RenamePlayerHitToVideoViews < ActiveRecord::Migration
  def change
    rename_column :plans, :player_hits, :video_views

    rename_column :sites, :plan_player_hits_reached_notification_sent_at,  :overusage_notification_sent_at

    remove_index :sites, :last_30_days_main_player_hits_total_count
    remove_index :sites, :last_30_days_extra_player_hits_total_count
    remove_index :sites, :last_30_days_dev_player_hits_total_count

    rename_column :sites, :last_30_days_main_player_hits_total_count,  :last_30_days_main_video_views
    rename_column :sites, :last_30_days_extra_player_hits_total_count, :last_30_days_extra_video_views
    rename_column :sites, :last_30_days_dev_player_hits_total_count,   :last_30_days_dev_video_views

    add_index :sites, :last_30_days_main_video_views
    add_index :sites, :last_30_days_extra_video_views
    add_index :sites, :last_30_days_dev_video_views

    add_column :sites, :last_30_days_invalid_video_views, :integer, default: 0
    add_column :sites, :last_30_days_embed_video_views, :integer, default: 0

    add_index :sites, :last_30_days_invalid_video_views
    add_index :sites, :last_30_days_embed_video_views
  end
end
