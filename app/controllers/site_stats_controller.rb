class SiteStatsController < ApplicationController
  skip_before_filter :authenticate_user!, if: :demo_site?
  before_filter :redirect_suspended_user
  before_filter :find_site_by_token!

  # GET /sites/:site_id/stats
  def index
    unless demo_site?
      @sites = current_user.sites.not_archived.with_plan.order(:hostname, :token)
    end

    respond_to do |format|
      format.html
      format.json {
        render json: Stat::Site.json(@site.token,
          period: params[:period] || 'minutes',
          demo: demo_site?
        )
      }
    end
  end

  # GET /sites/:site_id/stats/videos
  def videos
    respond_to do |format|
      format.json { render json: Stat::Video.top_videos(@site, params) }
    end
  end

end
