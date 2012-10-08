require_dependency 'services/sites/manager'

class AddonsController < ApplicationController
  before_filter :redirect_suspended_user, only: [:index]
  before_filter :find_sites_or_redirect_to_new_site, only: [:index, :thanks]
  before_filter :find_site_by_token!, only: [:update_all, :thanks]

  # GET /sites/:site_id/addons
  def index
    @site = current_user.sites.not_archived.includes(:billable_items, :app_designs, :addon_plans).find_by_token!(params[:site_id] || params[:id])
    @site = exhibit(@site)
    @app_designs = App::Design.all
  end

  # PUT /sites/:site_id/addons/update_all
  def update_all
    Services::Sites::Manager.new(@site).update_billable_items!(params[:app_designs], params[:addon_plans])

    redirect_to thanks_site_addons_path, notice: 'Add-ons successfully updated.'
  end

  def thanks
    respond_with(@site)
  end

end
