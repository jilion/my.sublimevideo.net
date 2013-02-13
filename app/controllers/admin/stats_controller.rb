class Admin::StatsController < Admin::AdminController
  respond_to :html, :json

  def index
    @selected_series = params.select { |p| %w[controller action].exclude? p }.keys.map { |p| p.split('.') }
    @selected_period = (params[:p] || "").split('-')
  end

  def show
    render params[:page]
  end

  def billings
    respond_to do |format|
      format.json { render json: Stats::BillingsStat.json }
    end
  end

  def revenues
    respond_to do |format|
      format.json { render json: Stats::RevenuesStat.json }
    end
  end

  def billable_items
    respond_to do |format|
      format.json { render json: Stats::BillableItemsStat.json }
    end
  end

  def users
    respond_to do |format|
      format.json { render json: Stats::UsersStat.json }
    end
  end

  def sites
    respond_to do |format|
      format.json { render json: Stats::SitesStat.json }
    end
  end

  def tweets
    respond_to do |format|
      format.json { render json: Stats::TweetsStat.json }
    end
  end

  def tailor_made_player_requests
    respond_to do |format|
      format.json { render json: Stats::TailorMadePlayerRequestsStat.json }
    end
  end

  def site_stats
    respond_to do |format|
      format.json { render json: Stats::SiteStatsStat.json }
    end
  end

  def site_usages
    respond_to do |format|
      format.json { render json: Stats::SiteUsagesStat.json }
    end
  end

  def more
    # Legacy metric
    @last_30_days_video_pageviews = SiteUsage.between(day: 31.days.ago.utc..Time.now.utc.yesterday).sum(:player_hits).to_i
    @total_video_pageviews = SiteUsage.sum(:player_hits).to_i

    @last_30_days_video_views = Stat::Site::Day.views_sum(from: 31.days.ago.utc, to: Time.now.utc.yesterday)
    @total_video_views = Stat::Site::Day.views_sum # all time views sum! FUCK YEAH!
  end

end
