class SiteStatsController < ApplicationController
  before_filter :redirect_suspended_user
  before_filter :find_site_by_token!
  skip_before_filter :authenticate_user!, if: :demo_site?

  # GET /sites/stats/:site_id
  # GET /sites/stats(/:token)
  def index
    @sites = demo_site? ? Site.where(token: SiteToken[:www]) : current_user.sites.not_archived.with_plan.order(:hostname, :token)

    respond_to do |format|
      format.html
      format.json { render json: Stat::Site.json(@token, params[:period] || 'minutes') }
    end
  end

  # GET /sites/:id/stats/videos
  def videos
    respond_to do |format|
      format.json { render json: Stat::Video.top_videos(@token, params) }
    end
  end

private

  def find_site_by_token!
    if demo_site?
      @site  = Site.find_by_token(SiteToken[:www])
      @token = 'demo'
    elsif params[:site_id]
      @site  = current_user.sites.not_archived.find_by_token!(params[:site_id])
      @token = @site.token
    end
  end

  def demo_site?
    (params[:site_id] || params[:id]) == 'demo'
  end

end
