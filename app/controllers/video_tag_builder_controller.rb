class VideoTagBuilderController < ApplicationController
  skip_before_filter :authenticate_user!

  # GET /video_tag_builder
  def new
    if user_signed_in?
      @site = current_user.sites.find_by_token!(params[:site_id]) if params[:site_id]
      @sites = current_user.sites.order(:hostname).select([:token, :hostname])
    end
  end

  # GET /video_tag_builder/iframe-embed
  def iframe_embed
    render layout: false
  end

end
