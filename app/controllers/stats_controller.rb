class StatsController < ApplicationController
  before_filter :redirect_suspended_user

  def index
    @site = Site.find_by_token(params[:site_id])

    respond_to do |format|
      format.html
      format.json { render json: @site.stats.last_data }
    end
  end

end
