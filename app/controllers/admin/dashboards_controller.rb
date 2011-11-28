class Admin::DashboardsController < AdminController

  def show
    # Legacy metric
    @last_30_days_video_pageviews = SiteUsage.between(31.days.ago.utc, Time.now.utc.yesterday).sum(:player_hits).to_i
    @total_video_pageviews = SiteUsage.sum(:player_hits).to_i

    @last_30_days_video_views = Stat::Site.views_sum(from: 31.days.ago.utc, to: Time.now.utc.yesterday)
    @total_video_views = Stat::Site.views_sum # all time views sum! FUCK YEAH!
  end

end
