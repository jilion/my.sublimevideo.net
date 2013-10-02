class SiteStatsController < ApplicationController
  skip_before_filter :authenticate_user!, if: :demo_site?
  before_filter :redirect_suspended_user, :_set_site
  before_filter :_redirect_user_without_stats_addon, unless: :demo_site?
  before_filter :_set_sites_or_redirect_to_new_site, only: [:index], unless: :demo_site?

  # GET /sites/:site_id/stats
  def index
    @stats_presenter = SiteStatsPresenter.new(@site, params)

    if stale?(last_modified: @stats_presenter.last_modified, etag: @stats_presenter.etag)
      respond_to do |format|
        format.html
        format.js
        # format.csv { send_file(_csv_file.path, filename: _csv_filename, type: 'text/csv') }
      end
    end
  end

  private

  def _csv_filename
    "site_stats-#{@site.token}-#{@stats_presenter.options[:source]}-#{@stats_presenter.options[:hours].to_i.hours.ago.change(min: 0)}-#{1.hour.ago.change(min: 0)}.csv"
  end

  # TODO
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
