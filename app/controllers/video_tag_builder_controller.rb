class VideoTagBuilderController < ApplicationController

  # GET /video_tag_builder
  def new
    @sites = current_user.sites.order(:hostname).select([:token, :hostname]) if user_signed_in?
  end

  # GET /video_tag_builder/iframe-embed
  def iframe_embed
    render layout: false
  end

private

  def find_site_by_token!
    @site = current_user.sites.find_by_token!(params[:site_id])
  end

end
