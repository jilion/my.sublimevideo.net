class My::SiteStatsController < MyController
  before_filter :redirect_suspended_user
  before_filter :find_site_by_token!
  skip_before_filter :authenticate_user!, if: :demo_site?

  # GET /sites/stats/:site_id
  # GET /sites/stats(/:token)
  def index
    @sites = current_user ? current_user.sites.not_archived.with_plan.order(:hostname, :token) : Site.where(token: 'demo')
    respond_to do |format|
      format.html
      format.json { render json: Stat::Site.json(@site.token, params[:period] || 'minutes') }
    end
  end

  # PUT /sites/:id/stats/trial
  def trial
    @site.stats_trial_started_at ||= Time.now.utc
    @site.save
    render nothing: true
  end

  # GET /sites/:id/stats/videos
  def videos
    respond_to do |format|
      format.json { render json: Stat::Video.top_videos(@site.token, params) }
    end
  end

private

  def find_site_by_token!
    if demo_site?
      @site = Site.find_by_token('demo')
    elsif params[:site_id]
      @site = current_user.sites.not_archived.find_by_token!(params[:site_id])
    end
  end
  
  def demo_site?
    (params[:token] || params[:site_id] || params[:id]) == 'demo'
  end

end
