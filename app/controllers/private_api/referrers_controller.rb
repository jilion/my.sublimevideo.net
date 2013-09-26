require 'has_scope'

# TODO Replace by SiteAdminStat

class PrivateApi::ReferrersController < SublimeVideoPrivateApiController
  has_scope :per, :by_hits
  has_scope :with_tokens, type: :array

  # GET /private_api/referrers
  def index
    @referrers = apply_scopes(Referrer.page(params[:page]))
    expires_in 2.minutes, public: true
    respond_with(@referrers)
  end

end
