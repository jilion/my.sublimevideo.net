require 'has_scope'

class PrivateApi::ReferrersController < SublimeVideoPrivateApiController
  has_scope :per, :by_hits
  has_scope :with_tokens, type: :array

  # GET /private_api/referrers
  def index
    respond_with(apply_scopes(Referrer.page(params[:page])))
  end

end
