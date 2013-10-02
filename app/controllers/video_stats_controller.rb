require 'csv'

class VideoStatsController < ApplicationController
  before_filter :redirect_suspended_user, :require_video_early_access, :_set_site, :_set_video_tag, only: [:index]
  before_filter :_redirect_user_without_stats_addon, :_set_sites_or_redirect_to_new_site, only: [:index]

  respond_to :html, :js, :csv

  etag { current_user.id }

  # GET /sites/:site_id/videos/:id/stats
  def index
    @stats_presenter = VideoStatPresenter.new(@video_tag, params)

    if stale?(last_modified: @stats_presenter.last_modified, etag: @stats_presenter.etag)
      respond_to do |format|
        format.html
        format.js
        format.csv { send_file(_csv_file.path, filename: _csv_filename, type: 'text/csv') }
      end
    end
  end

  private

  def _redirect_user_without_stats_addon
    redirect_to root_url unless @site.realtime_stats_active?
  end

  def _csv_filename
    "video_stats-#{@video_tag.uid}-#{@stats_presenter.options[:source]}-#{@stats_presenter.options[:hours].to_i.hours.ago.change(min: 0)}-#{1.hour.ago.change(min: 0)}.csv"
  end

  def _csv_file
    tempfile = Tempfile.new(['export', '.csv'])
    CSV.open(tempfile, 'wb') do |csv|
      csv << %w[time loads plays]
      @stats_presenter.loads.each_with_index do |(time, loads), i|
        csv << [Time.at(time / 1000), loads, @stats_presenter.plays[i].last]
      end
    end
    tempfile
  end

end
