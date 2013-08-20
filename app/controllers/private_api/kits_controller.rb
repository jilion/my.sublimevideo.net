require 'has_scope'

class PrivateApi::KitsController < SublimeVideoPrivateApiController
  before_filter :_load_site, :_load_kits, only: [:index]

  has_scope :per

  # GET /private_api/sites/:site_id/kits
  def index
    expires_in 2.minutes, public: true
    respond_with(@kits)
  end

  private

  def _load_site
    @site = Site.with_state('active').where(token: params[:site_id]).first!
  end

  def _load_kits
    @kits = apply_scopes(@site.kits.page(params[:page]))
  end
end
