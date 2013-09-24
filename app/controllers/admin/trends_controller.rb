class Admin::TrendsController < Admin::AdminController
  respond_to :html, :json

  def index
    @selected_period = params.delete(:p) { '' }.split('-')
    @selected_series = params.select { |key| %w[controller action].exclude?(key) }.keys.map { |p| p.split('.') }
  end

  def billings
    respond_to do |format|
      format.json { render json: BillingsTrend.json }
    end
  end

  def revenues
    respond_to do |format|
      format.json { render json: RevenuesTrend.json }
    end
  end

  def billable_items
    respond_to do |format|
      format.json { render json: BillableItemsTrend.json }
    end
  end

  def users
    respond_to do |format|
      format.json { render json: UsersTrend.json }
    end
  end

  def sites
    respond_to do |format|
      format.json { render json: SitesTrend.json }
    end
  end

  def tweets
    respond_to do |format|
      format.json { render json: TweetsTrend.json }
    end
  end

  def tailor_made_player_requests
    respond_to do |format|
      format.json { render json: TailorMadePlayerRequestsTrend.json }
    end
  end

  def site_stats
    respond_to do |format|
      format.json { render json: SiteStatsTrend.json }
    end
  end

  def site_usages
    respond_to do |format|
      format.json { render json: SiteUsagesTrend.json }
    end
  end

  def more
    # Legacy metric
    @last_30_days_video_pageviews = SiteUsage.between(day: 31.days.ago.utc..Time.now.utc.yesterday).sum(:player_hits).to_i
    @total_video_pageviews = SiteUsage.sum(:player_hits).to_i

    @last_30_days_video_views = Stat::Site::Day.views_sum(from: 31.days.ago.utc.midnight, to: Time.now.utc.yesterday.end_of_day)
    @total_video_views = Stat::Site::Day.views_sum # all time views sum! FUCK YEAH!
  end

end
