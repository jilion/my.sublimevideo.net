class Admin::StatsController < AdminController
  respond_to :html, :json

  def index
  end

  def show
    render params[:id]
  end

  def users
    respond_to do |format|
      format.json { render json: UsersStat.json }
    end
  end

  def sites
    respond_to do |format|
      format.json { render json: SitesStat.json }
    end
  end

  def tweets
    respond_to do |format|
      format.json { render json: TweetsStat.json(keyword: 'sublimevideo') }
    end
  end

end
