require 'has_scope'

class PrivateApi::AddonsController < SublimeVideoPrivateApiController
  before_filter :_set_site, only: [:index]
  before_filter :_set_addon_plans, only: [:index]

  has_scope :per, :state

  # GET /private_api/sites/:site_id/addons
  def index
    expires_in 2.minutes, public: true
    respond_with(@addon_plans)
  end

  private

  def _set_site
    @site = Site.with_state('active').where(token: params[:site_id]).first!
  end

  def _set_addon_plans
    subscriptions = apply_scopes(BillableItem.addon_plans.where(site_id: @site.id).page(params[:page]))
    @addon_plans = AddonPlan.includes(:addon).find(*subscriptions.pluck(:item_id))
  end
end
