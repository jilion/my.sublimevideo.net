class VideoTagsController < ApplicationController
  skip_before_filter :authenticate_user!, if: :demo_site?
  before_filter :redirect_suspended_user
  before_filter :find_site_by_token!

  # GET /sites/:site_id/video_tags/:id
  def show
    @video_tag = VideoTag.where(st: @site.token, u: params[:id]).first

    respond_to do |format|
      format.json { render json: @video_tag.try(:meta_data) }
    end
  end

end
