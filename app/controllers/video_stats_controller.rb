class VideoStatsController < ApplicationController
  before_filter :redirect_suspended_user, :_set_site, :_set_video_tag, only: [:index]
  before_filter :_redirect_user_without_stats_addon, :_set_sites_or_redirect_to_new_site, only: [:index]

  respond_to :html, :js, :csv

  etag { current_user.id }

  # GET /sites/:site_id/videos/:video_tag_id/stats
  def index
    @stats_presenter = VideoStatsPresenter.new(@video_tag, params)

    if stale?(last_modified: @stats_presenter.last_modified, etag: @stats_presenter.etag)
      respond_to do |format|
        format.html
        format.js { render 'stats/index' }
        format.csv do
          send_file(*VideoStatsCsvPresenter.new(@video_tag, @stats_presenter).as_sent_file)
        end
      end
    end
  end

end
