class Admin::ReferrersController < Admin::AdminController
  respond_to :js, :html

  before_filter :load_referrers

  has_scope :by_hits, :by_badge_hits, :by_contextual_hits, :by_updated_at, :by_created_at

  # GET /referrers
  def index
    respond_with(@referrers)
  end

  # GET /referrers/pages
  def pages
    respond_with(@referrers, paginate: true)
  end

  private

  def load_referrers
    @referrers = apply_scopes(Referrer.criteria)
  end

end
