class My::SiteStatsController < MyController
  before_filter :redirect_suspended_user
  before_filter :find_site_by_token!

  # GET /sites/stats/:site_id
  # GET /sites/stats(/:token)
  def index
    respond_to do |format|
      format.html
      format.json { render json: Stat::Site.json(@site.token, params[:period] || 'minutes') }
    end
  end

  # GET /sites/:id/stats/videos
  def videos
    respond_to do |format|
      format.json { render json: Stat::Video.top_videos(@site.token, params) }
    end
  end

private

  def find_site_by_token!
    @site = current_user.sites.not_archived.find_by_token!(params[:site_id]) if params[:site_id]
  end

end
