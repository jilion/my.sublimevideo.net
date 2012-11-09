require_dependency 'mime_type_guesser'

class VideoCodesController < ApplicationController
  skip_before_filter :authenticate_user!, if: :public_page?
  before_filter :redirect_suspended_user, only: [:new]
  before_filter :find_sites_or_redirect_to_new_site, :redirect_routes, :find_site_by_token!, only: [:new, :show]
  before_filter :require_video_early_access, only: [:show]

  # GET /sites/:site_id/video-codes/new
  ## Private page for users with early access to video:
  # GET /sites/:site_id/video-codes/:vid
  #
  ## Public page:
  # GET /video-code-generator
  def new
    @kit = exhibit(@site.default_kit)
  end

  def show
    @video_tag = VideoTag.where(st: @site.token, u: params[:id]).first
  end

  # GET /video-code-generator/mime-type-check
  def mime_type_check
    render text: MimeTypeGuesser.guess(params[:url]), layout: false
  end

  # GET /video-code-generator/iframe-embed
  def iframe_embed
    render layout: false
  end

  private

  def redirect_routes
    if user_signed_in?
      redirect_to(new_site_video_code_path(current_user.sites.not_archived.by_date.first.token)) and return if public_page?
    else
      redirect_to(video_code_generator_path) and return unless public_page?
    end
  end

end
