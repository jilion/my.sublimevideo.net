class VideoTagsController < ApplicationController
  skip_before_filter :authenticate_user!, if: :demo_site?
  before_filter :redirect_suspended_user
  before_filter :require_video_early_access, only: [:index]
  before_filter :find_site_by_token!
  before_filter :find_sites_or_redirect_to_new_site, only: [:index]
  respond_to :html, :js, only: [:index]
  respond_to :json, only: [:show]

  # Filter
  FILTER_PARAMS = %w[
    last_30_days_active
    last_90_days_active
    hosted_on_sublimevideo
    not_hosted_on_sublimevideo
    all
  ]
  FILTER_PARAMS.each { |p| has_scope p, type: :boolean }
  # Sort
  SORT_PARAMS = %w[
    by_name
    by_date
    by_state
  ]
  SORT_PARAMS.each { |p| has_scope p }

  # GET /sites/:site_id/videos
  def index
    @video_tags = @site.video_tags
    @video_tags = apply_filter(@video_tags)
    @video_tags = apply_scopes(@video_tags)
      .by_date(params[:by_date] || 'desc')

    respond_with(@video_tags, per_page: 10)
  end

  # GET /sites/:site_id/video_tags/:id
  def show
    @video_tag = VideoTag.where(st: @site.token, u: params[:id]).first

    respond_with(@video_tag) do |format|
      format.json { render json: @video_tag.try(:meta_data) }
    end
  end

private

  def apply_filter(video_tags)
    if FILTER_PARAMS.include?(params[:filter])
      @video_tags.send(params[:filter])
    else
      @video_tags.last_30_days_active
    end
  end

end
