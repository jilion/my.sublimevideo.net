require 'has_scope'

class PrivateApi::KitsController < SublimeVideoPrivateApiController
  before_filter :_find_site_by_token!, :_find_kits, only: [:index]

  has_scope :per

  # GET /private_api/sites/:id/kits
  def index
    expires_in 2.minutes, public: true
    respond_with(@kits)
  end

  private

  def _find_site_by_token!
    @site = Site.with_state('active').find_by_token!(params[:site_id])
  end

  def _find_kits
    @kits = apply_scopes(@site.kits.page(params[:page]))
  end
end
