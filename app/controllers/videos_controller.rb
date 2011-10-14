class VideosController < ApplicationController
  before_filter :redirect_suspended_user
  before_filter :find_site_by_token!

  # GET /sites/:site_id/video/new
  def new
    respond_with(@site)
  end

private

  def find_site_by_token!
    @site = current_user.sites.find_by_token!(params[:site_id])
  end

end
