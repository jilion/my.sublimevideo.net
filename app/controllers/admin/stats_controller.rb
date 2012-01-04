class Admin::StatsController < AdminController
  respond_to :html, :json

  def index
  end

  def show
    render params[:id]
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

end
