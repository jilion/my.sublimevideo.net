require_dependency 'stats_demo_helper'

class VideoTagsController < ApplicationController
  include StatsDemoHelper

  before_filter :redirect_suspended_user
  before_filter :find_site_by_token!
  skip_before_filter :authenticate_user!, if: :demo_site?

  # GET /sites/:site_id/video_tags/:id
  def show
    @video_tag = VideoTag.where(st: @site.token, u: params[:id]).first

    respond_to do |format|
      format.json { render json: @video_tag.try(:meta_data) }
    end
  end

end
