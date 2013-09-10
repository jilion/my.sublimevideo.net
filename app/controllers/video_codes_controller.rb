class VideoCodesController < ApplicationController
  before_filter :redirect_suspended_user, only: [:new]
  before_filter :_set_sites_or_redirect_to_new_site, :_redirect_to_first_site, :_set_site, only: [:new, :edit]
  before_filter :require_video_early_access, :_set_video, only: [:edit]

  # GET /sites/:site_id/publish-video
  ## Private page for users with early access to video:
  # GET /sites/:site_id/video-codes/:vid
  def new
  end

  def edit
  end

  # GET /mime-type-check
  def mime_type_check
    checker = HttpContentType::Checker.new(params[:url])
    content_type = if checker.error?
      'error'
    elsif !checker.found?
      'not-found'
    else
      checker.content_type
    end
    render text: content_type, layout: false
  end

  private

  def _redirect_to_first_site
    unless params[:site_id]
      redirect_to(new_site_video_code_path(current_user.sites.not_archived.by_date.first.token)) and return
    end
  end

end
