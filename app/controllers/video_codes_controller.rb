require_dependency 'mime_type_guesser'

class VideoCodesController < ApplicationController
  skip_before_filter :authenticate_user!, if: :public_page?
  before_filter :redirect_suspended_user, :find_site_by_token!, only: [:new]

  # GET /sites/:site_id/video-codes/new
  def new
    find_sites_or_redirect_to_new_site unless public_page?
  end

  # GET /video-code-generator/mime-type-check
  def mime_type_check
    render text: MimeTypeGuesser.guess(params[:url]), layout: false
  end

  # GET /video-code-generator/iframe-embed
  def iframe_embed
    render layout: false
  end

end
