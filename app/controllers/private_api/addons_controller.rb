require 'has_scope'

class PrivateApi::AddonsController < SublimeVideoPrivateApiController
  before_filter :_find_site_by_token!, only: [:index]
  before_filter :_find_addon_plans, only: [:index]

  has_scope :per, :state

  # GET /private_api/sites/:id/addons
  def index
    expires_in 2.minutes
    respond_with(@addon_plans)
  end

  private

  def _find_site_by_token!
    @site = Site.with_state('active').find_by_token!(params[:site_id])
  end

  def _find_addon_plans
    subscriptions = apply_scopes(BillableItem.addon_plans.where(site_id: @site.id).page(params[:page]))
    @addon_plans = AddonPlan.includes(:addon).find(subscriptions.pluck(:item_id))
  end
end
