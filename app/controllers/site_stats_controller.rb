require_dependency 'stats_demo_helper'

class SiteStatsController < ApplicationController
  include StatsDemoHelper

  before_filter :redirect_suspended_user
  before_filter :find_site_by_token!
  skip_before_filter :authenticate_user!, if: :demo_site?

  # GET /sites/stats/:site_id
  def index
    @sites = demo_site? ? Site.where(token: SiteToken[:www]) : current_user.sites.not_archived.with_plan.order(:hostname, :token)

    respond_to do |format|
      format.html
      format.json { render json: Stat::Site.json(@token, params[:period] || 'minutes') }
    end
  end

  # GET /sites/:site_id/stats/videos
  def videos
    respond_to do |format|
      format.json { render json: Stat::Video.top_videos(@token, params) }
    end
  end

end
