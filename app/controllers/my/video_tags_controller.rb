class My::VideoTagsController < MyController
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

private

  def find_site_by_token!
    if demo_site?
      @site  = Site.find_by_token(SiteToken.www)
    elsif params[:site_id]
      @site = current_user.sites.not_archived.find_by_token!(params[:site_id])
    end
  end

  def demo_site?
    params[:site_id] == 'demo'
  end

end
