object @site

attributes *((params[:select] || [:accessible_stage, :addons_updated_at, :alexa_rank, :archived_at, :badged, :current_assistant_step, :dev_hostnames, :extra_hostnames, :first_admin_starts_on, :google_rank, :last_30_days_admin_starts, :last_30_days_starts, :last_30_days_starts_array, :last_30_days_video_tags, :loaders_updated_at, :path, :refunded_at, :settings_updated_at, :staging_hostnames, :state, :user_id, :wildcard]) + [:token, :hostname, :created_at, :updated_at]).uniq

node(:tags) { |site| site.tag_list }

child(default_kit: :default_kit) { extends('private_api/kits/show') } unless params.has_key?(:select)
