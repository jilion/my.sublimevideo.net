class VideosController < ApplicationController
  before_filter :redirect_suspended_user, only: [:index]
  before_filter :find_sites_or_redirect_to_new_site, only: [:index]

  # GET /sites/:site_id/videos
  def index
    @site   = current_user.sites.not_archived.find_by_token!(params[:site_id])
    @videos = []

    respond_with(@videos)
  end

end
