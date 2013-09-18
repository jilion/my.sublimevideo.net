class VideoStatsController < ApplicationController
  before_filter :redirect_suspended_user, :_set_site, :_set_video_tag, only: [:index]
  before_filter :_redirect_user_without_stats_addon, :_set_sites_or_redirect_to_new_site, only: [:index]

  respond_to :html, :js

  etag { current_user.id }

  # GET /sites/:site_id/videos/:id/stats
  def index
    @stats_presenter = VideoStatPresenter.new(@video_tag, params)

    stats_for_last_modified = if params[:last_stats_by_minute_only]
      @stats_presenter.last_stats_by_minute
    else
      @stats_presenter.last_stats_by_hour
    end

    if stale?(last_modified: stats_for_last_modified.map { |h| h[:updated_at] }.max, etag: "#{@video_tag}_#{@stats_presenter.options[:hours]}")
      respond_to do |format|
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
