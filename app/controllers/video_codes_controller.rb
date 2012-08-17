require_dependency 'mime_type_guesser'

class VideoCodesController < ApplicationController
  skip_before_filter :authenticate_user!

  # GET /video-code-generator
  def new
    if user_signed_in?
      @sites = current_user.sites.not_archived.order(:hostname).select([:token, :hostname, :extra_hostnames, :wildcard, :path])
    end
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
