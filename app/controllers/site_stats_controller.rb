class SiteStatsController < ApplicationController
  before_filter :redirect_suspended_user
  before_filter :find_site_by_token!

  # GET /sites/:id/stats
  def index
    respond_to do |format|
      format.html
      format.json { render json: Stat::Site.json(@site.token, params[:period] || 'minutes') }
    end
  end

  # PUT /sites/:id/stats/trial
  def trial
    @site.stats_trial_started_at ||= Time.now.utc
    @site.save
    render nothing: true
  end

  # GET /sites/:id/stats/videos
  def videos
    respond_to do |format|
      format.json { render json: Stat::Video.top_videos(@site.token, params) }
    end
  end

private

  def find_site_by_token!
    @site = current_user.sites.not_archived.find_by_token!(params[:site_id])
  end

end
