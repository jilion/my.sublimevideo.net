require_dependency 'addons/addonships_manager'

class AddonsController < ApplicationController
  before_filter :redirect_suspended_user, only: [:index]
  before_filter :find_sites_or_redirect_to_new_site, only: [:index]
  before_filter :find_site_by_token!, only: [:index, :update_all]

  # GET /sites/:site_id/addons
  def index
    @addons = Addons::Addon.all.group_by(&:category)

    respond_with(@addons)
  end

  # PUT /sites/:site_id/addons/update_all
  def update_all
    Addons::AddonshipsManager.update_addonships_for_site!(@site, params[:site_addons])

    redirect_to site_addons_path(@site), notice: 'Add-ons successfully updated.'
  end

end
