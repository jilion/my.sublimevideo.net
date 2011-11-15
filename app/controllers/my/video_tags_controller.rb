class My::VideoTagsController < ApplicationController
  before_filter :redirect_suspended_user
  before_filter :find_site_by_token!

  # GET /sites/:site_id/video_tags/:id
  def show
    @video_tag = VideoTag.where(st: @site.token, u: params[:id]).first
    
    respond_to do |format|
      format.json { render json: @video_tag.try(:meta_data) }
    end
  end

private

  def find_site_by_token!
    @site = current_user.sites.not_archived.find_by_token!(params[:site_id])
  end

end
