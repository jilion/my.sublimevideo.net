class Admin::DashboardsController < Admin::AdminController

  before_filter :compute_date_range

  def show
    # Legacy metric
    @last_30_days_usage = SiteUsage.between(31.days.ago.utc, Time.now.utc.yesterday).sum(:player_hits).to_i
    @total_usage = SiteUsage.sum(:player_hits).to_i

    @last_30_days_video_views = SiteStat.d_between(31.days.ago.utc, Time.now.utc.yesterday.end_of_day).inject(0) { |sum, ss| sum + ss.vv['m'] + ss.vv['e'] }.to_i
    @total_video_views = SiteStat.collection.group(initial: { sum: 0 }, reduce: 'function(doc, prev){ prev.sum += (isNaN(doc.vv.m) ? 0 : doc.vv.m) + (isNaN(doc.vv.e) ? doc.vv.e : 0); }').first['sum'].to_i
  end

end
