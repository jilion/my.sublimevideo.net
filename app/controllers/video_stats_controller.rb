class VideoStatsController < ApplicationController
  before_filter :redirect_suspended_user, :_set_site, :_set_video, only: [:index]
  before_filter :_redirect_user_without_stats_addon, :_set_sites_or_redirect_to_new_site, only: [:index]

  respond_to :html, :js

  etag { current_user.id }

  # GET /sites/:site_id/videos/:id/stats
  def index
    params[:hours]  ||= 24
    params[:source] ||= 'a'
    @stats = VideoStat.last_hours_stats(@video, params[:hours])

    if stale?(last_modified: @stats.map { |h| h[:updated_at] }.max, etag: "#{@video}_#{params[:hours]}")
      respond_with(@stats) do |format|
        format.html
        format.js
      end
    end
  end

  private

  def _redirect_user_without_stats_addon
    redirect_to root_url unless @site.subscribed_to?(AddonPlan.get('stats', 'realtime'))
  end

end
