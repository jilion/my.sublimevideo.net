class AddonsController < ApplicationController
  skip_before_filter :authenticate_user!, only: [:show]
  before_filter :redirect_to_features_page_if_user_not_signed_in!, only: [:show]
  before_filter :redirect_suspended_user, only: [:index, :show, :subscribe]
  before_filter :find_sites_or_redirect_to_new_site, only: [:index, :show, :subscribe]
  before_filter :load_site, only: [:subscribe]

  # GET /addons
  # GET /sites/:site_id/addons
  def index
    unless @site = current_user.sites.not_archived.where(token: params[:site_id]).first
      redirect_to [@sites.first, :addons]
    end

    @site = exhibit(@site)
  end

  # GET /addons/:id
  # GET /sites/:site_id/addons/:id
  def show
    @addon = Addon.get(params[:id])

    unless @site = current_user.sites.not_archived.where(token: params[:site_id]).first
      redirect_to site_addon_path(@sites.first, @addon, p: params[:p])
    end
  end

  # PUT /sites/:site_id/addons/subscribe
  def subscribe
    SiteManager.new(@site).update_billable_items(params[:designs], params[:addon_plans])

    redirect_to [@site, :addons], notice: t('flash.addons.subscribe.notice')
  end

  private

  def redirect_to_features_page_if_user_not_signed_in!
    unless user_signed_in?
      if params.has_key?(:public)
        redirect_to(layout_url("modular-player##{params[:id]}"))
      else
        authenticate_user!
      end
    end
  end

  def find_sites
    @sites = current_user.sites.not_archived.by_last_30_days_billable_video_views
  end

end
