class SiteStatsController < ApplicationController
  skip_before_filter :authenticate_user!, if: :demo_site?
  before_filter :redirect_suspended_user, :find_site_by_token!
  before_filter :redirect_user_without_stats_addon, unless: :demo_site?

  # GET /sites/:site_id/stats
  def index
    unless demo_site?
      @sites = current_user.sites.not_archived.order(:hostname, :token)
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
      format.json { render json: Stat::Video.top_videos(@site.token, params) }
    end
  end

  private

  def redirect_user_without_stats_addon
    redirect_to root_url unless @site.addon_is_active?(Addons::Addon.get('stats', 'standard'))
  end

end
