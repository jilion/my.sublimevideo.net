class Admin::StatsController < AdminController
  respond_to :html, :json

  def index
  end

  def show
    render params[:page]
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
      format.json { render json: Stats::TweetsStat.json(keyword: 'sublimevideo') }
    end
  end
  
  def site_stats
    respond_to do |format|
      format.json { render json: Stats::SiteStatsStat.json }
    end
  end
  
  def usages
    respond_to do |format|
      # format.json { render json: Stat::Site.json(nil, 'days') }
    end
  end

  def more
    # Legacy metric
    @last_30_days_video_pageviews = SiteUsage.between(31.days.ago.utc, Time.now.utc.yesterday).sum(:player_hits).to_i
    @total_video_pageviews = SiteUsage.sum(:player_hits).to_i

    @last_30_days_video_views = Stat::Site.views_sum(from: 31.days.ago.utc, to: Time.now.utc.yesterday)
    @total_video_views = Stat::Site.views_sum # all time views sum! FUCK YEAH!
  end

end
