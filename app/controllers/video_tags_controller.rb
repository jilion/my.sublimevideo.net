class VideoTagsController < ApplicationController
  include VideoTagsHelper

  skip_before_filter :authenticate_user!, if: :demo_site?
  before_filter :redirect_suspended_user
  before_filter :_set_site
  before_filter :_set_sites_or_redirect_to_new_site, only: [:index]
  before_filter :_set_video_tag, only: [:show]

  respond_to :html, only: [:index]
  respond_to :json, only: [:show]

  etag { current_user.id }

  FILTER_PARAMS = %w[
    last_30_days_active
    last_90_days_active
    last_365_days_active
  ]
  SORT_PARAMS = %w[
    by_date
    by_title
    by_last_days_starts
  ]

  # GET /sites/:site_id/videos
  def index
    @video_tags = VideoTag.all(_index_params)

    if stale?(last_modified: @video_tags.map(&:updated_at).max, etag: @video_tags.map { |v| [v.id, v.updated_at] })
      respond_with(@video_tags)
    end
  end

  # GET /sites/:site_id/video_tags/:id
  def show
    if stale?(@video_tag)
      respond_with(@video_tag) do |format|
        format.json { render json: @video_tag.try(:backbone_data) }
      end
    end
  end

  private

  def _index_params
    index_params = { _site_token: @site.token, with_valid_uid: true, per: 10 }
    if params[:filter].in?(FILTER_PARAMS)
      index_params[params[:filter]] = true
    else
      index_params[:last_30_days_active] = true
    end
    if sort_key = params.keys.detect { |k| k.in?(SORT_PARAMS) }
      if sort_key == 'by_last_days_starts'
        index_params["by_last_#{last_starts_days}_days_starts"] = params[sort_key]
      else
        index_params[sort_key] = params[sort_key]
      end
    else
      index_params[:by_date] = 'desc'
    end
    [:search, :page].each { |p| index_params[p] = params[p] if params.key?(p) }
    index_params
  end

end
