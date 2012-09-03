class VideoTagsController < ApplicationController
  skip_before_filter :authenticate_user!, if: :demo_site?
  before_filter :redirect_suspended_user
  before_filter :require_video_early_access, only: [:index]
  before_filter :find_site_by_token!
  before_filter :find_sites_or_redirect_to_new_site, only: [:index]
  respond_to :html, only: [:index]
  respond_to :json, only: [:show]

  # GET /sites/:site_id/videos
  def index
    @video_tags = @site.video_tags

    respond_with(@video_tags)
  end

  # GET /sites/:site_id/video_tags/:id
  def show
    @video_tag = VideoTag.where(st: @site.token, u: params[:id]).first

    respond_with(@video_tag) do |format|
      format.json { render json: @video_tag.try(:meta_data) }
    end
  end

private

  def require_video_early_access
    redirect_to root_url unless early_access?('video')
  end

end
