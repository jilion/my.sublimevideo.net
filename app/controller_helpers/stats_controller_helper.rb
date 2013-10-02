module StatsControllerHelper

  def _redirect_user_without_stats_addon
    redirect_to root_url unless @site.realtime_stats_active?
  end

end
