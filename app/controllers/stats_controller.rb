class StatsController < ApplicationController
  before_filter :redirect_suspended_user

  def index
    @site = Site.find_by_token(params[:site_id])
  end

end