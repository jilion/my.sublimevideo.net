require_dependency 'service/site'

class AddonsController < ApplicationController
  before_filter :redirect_suspended_user, only: [:index, :directory]
  before_filter :find_sites_or_redirect_to_new_site, only: [:index, :directory]
  before_filter :find_site_by_token!, only: [:update_all]

  # GET /addons
  def directory
    case current_user.sites.not_archived.count
    when 1
      p = { h: params[:h] } if params[:h]
      redirect_to site_addons_url(current_user.sites.not_archived.first, p)
    else
      redirect_to [:sites]
    end
  end

  # GET /sites/:site_id/addons
  def index
    @site = current_user.sites.not_archived.find_by_token!(params[:site_id] || params[:id])
    @site = exhibit(@site)
  end

  # PUT /sites/:site_id/addons/update_all
  def update_all
    Service::Site.new(@site).update_billable_items(params[:app_designs], params[:addon_plans])

    redirect_to [@site, :addons], notice: t('flash.addons.update_all.notice')
  end

end
