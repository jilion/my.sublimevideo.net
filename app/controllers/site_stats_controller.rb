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
        format.js { render 'stats/index' }
        format.csv do
          send_file(*SiteStatsCsvPresenter.new(@site, @stats_presenter).as_sent_file)
        end
      end
    end
  end

end
