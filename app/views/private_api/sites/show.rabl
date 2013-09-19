object @site
cache [@site, params.sort.hash.to_s]

attributes *((params[:select] || [:accessible_stage, :addons_updated_at, :alexa_rank, :archived_at, :badged, :current_assistant_step, :dev_hostnames, :extra_hostnames, :first_billable_plays_at, :first_paid_plan_started_at, :first_plan_upgrade_required_alert_sent_at, :google_rank, :last_30_days_billable_video_views_array, :last_30_days_dev_video_views, :last_30_days_embed_video_views, :last_30_days_extra_video_views, :last_30_days_invalid_video_views, :last_30_days_main_video_views, :last_30_days_video_tags, :loaders_updated_at, :next_cycle_plan_id, :overusage_notification_sent_at, :path, :pending_plan_cycle_ended_at, :pending_plan_cycle_started_at, :pending_plan_id, :pending_plan_started_at, :plan_cycle_ended_at, :plan_cycle_started_at, :plan_id, :plan_started_at, :refunded_at, :settings_updated_at, :staging_hostnames, :state, :trial_started_at, :user_id, :wildcard]) + [:token, :hostname, :created_at, :updated_at]).uniq

node(:tags) { |site| site.tag_list } if !params.has_key?(:select) || params[:select].include?('tags')

child(default_kit: :default_kit) { extends('private_api/kits/show') } unless params.has_key?(:select)
