require 'has_scope'

class PrivateApi::KitsController < SublimeVideoPrivateApiController
  include ApisControllerHelper

  before_filter :_set_site, :_set_kits, only: [:index]

  has_scope :per

  # GET /private_api/sites/:site_id/kits
  def index
    _with_cache_control { respond_with(@kits) }
  end

  private

  def _set_site
    @site = Site.with_state('active').where(token: params[:site_id]).first!
  end

  def _set_kits
    @kits = apply_scopes(@site.kits.page(params[:page]))
  end
end
