class StatsController < ApplicationController
  before_filter :redirect_suspended_user
  before_filter :find_site_by_token!

  # GET /sites/:id/stats
  def index
    respond_to do |format|
      format.html
      format.json { render json: Stat::Site.json(@site.token, params[:period] || 'minutes') }
    end
  end

  # POST /sites/:id/stats/trial
  def trial
    @site.stats_trial_started_at ||= Time.now.utc
    @site.save
    render nothing: true
  end

private

  def find_site_by_token!
    @site = current_user.sites.not_archived.find_by_token!(params[:site_id])
  end

end
