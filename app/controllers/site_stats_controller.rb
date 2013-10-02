class SiteStatsController < ApplicationController
  skip_before_filter :authenticate_user!, if: :demo_site?
  before_filter :redirect_suspended_user, :_set_site
  before_filter :_redirect_user_without_stats_addon, unless: :demo_site?
  before_filter :_set_sites_or_redirect_to_new_site, only: [:index], unless: :demo_site?

  # GET /sites/:site_id/stats
  def index
    respond_to do |format|
      format.html
      format.json
    end
  end

  private

  def _redirect_user_without_stats_addon
    redirect_to root_url unless @site.realtime_stats_active?
  end

end
