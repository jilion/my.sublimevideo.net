class VideoStatsController < ApplicationController
  before_filter :redirect_suspended_user, :_set_site, :_set_video, only: [:index]
  before_filter :_redirect_user_without_stats_addon, :_set_sites_or_redirect_to_new_site, only: [:index]

  respond_to :html, :js

  # GET /sites/:site_id/videos/:id/stats
  def index
    @stats = VideoStat.last_hours_stats(@video, 24)
    puts params
    puts 'FUCK!!!!!!!!!!!!!!!!!!!!!!!!!!!!!'
    puts @stats
  end

  private

  def _redirect_user_without_stats_addon
    redirect_to root_url unless @site.subscribed_to?(AddonPlan.get('stats', 'realtime'))
  end

end
