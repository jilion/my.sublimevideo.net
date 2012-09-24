require_dependency 'addons/addonship_manager'

class AddonsController < ApplicationController
  before_filter :redirect_suspended_user, only: [:index]
  before_filter :find_sites_or_redirect_to_new_site, only: [:index]

  # GET /sites/:site_id/addons
  def index
    @site   = current_user.sites.not_archived.find_by_token!(params[:site_id])
    @addons = Addons::Addon.all.group_by(&:category)

    respond_with(@addons)
  end

  # PUT /sites/:site_id/addons/update_all
  def update_all
    @site = current_user.sites.not_archived.find_by_token!(params[:site_id])
    Addons::AddonshipManager.new(@site).update_addonships!(params[:site_addons])

    redirect_to site_addons_path(@site), notice: 'Add-ons successfully updated.'
  end

end
