require_dependency 'services/sites/addonship'

class AddonsController < ApplicationController
  before_filter :redirect_suspended_user, only: [:index]
  before_filter :find_sites_or_redirect_to_new_site, only: [:index, :thanks]
  before_filter :find_site_by_token!, only: [:index, :update_all, :thanks]

  # GET /sites/:site_id/addons
  def index
  end

  # PUT /sites/:site_id/addons/update_all
  def update_all
    Services::Sites::Addonship.new(@site).update_addonships!(params[:site_addons])

    redirect_to thanks_site_addons_path, notice: 'Add-ons successfully updated.'
  end

  def thanks
    respond_with(@site)
  end

end
