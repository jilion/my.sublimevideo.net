class VideoTagsController < ApplicationController
  skip_before_filter :authenticate_user!, if: :demo_site?
  before_filter :redirect_suspended_user
  before_filter :require_video_early_access, only: [:index]
  before_filter :_set_site
  before_filter :_set_sites_or_redirect_to_new_site, only: [:index]

  respond_to :html, only: [:index]
  respond_to :json, only: [:show]

  FILTER_PARAMS = %w[
    last_30_days_active
    last_90_days_active
    last_365_days_active
    all
    inactive
  ]
  SORT_PARAMS = %w[
    by_date
    by_title
    by_last_30_days_starts
    by_last_90_days_starts
    by_last_365_days_starts
  ]

  # GET /sites/:site_id/videos
  def index
    @video_tags = VideoTag.all(_index_params)

    respond_with(@video_tags)
  end

  # GET /sites/:site_id/video_tags/:id
  def show
    @video_tag = VideoTag.find(params[:id], _site_token: @site.token)

    respond_with(@video_tag) do |format|
      format.json { render json: @video_tag.try(:backbone_data) }
    end
  end

private

  def _index_params
    index_params = { _site_token: @site.token, with_valid_uid: true }
    if params[:filter].in?(FILTER_PARAMS)
      index_params[params[:filter]] = true
    else
      index_params[:last_30_days_active] = true
    end
    if sort_key = params.keys.detect { |k| k.in?(SORT_PARAMS) }
      index_params[sort_key] = params[sort_key]
    else
      index_params[:by_date] = 'desc'
    end
    [:search, :page].each { |p| index_params[p] = params[p] if params.key?(p) }
    index_params
  end

end
