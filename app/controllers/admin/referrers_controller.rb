class Admin::ReferrersController < Admin::AdminController
  respond_to :js, :html

  before_filter :set_default_scope, :load_referrers

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

  def set_default_scope
    params[:by_updated_at] = 'desc' if (scopes_configuration.keys & params.keys.map(&:to_sym)).empty?
  end

  def load_referrers
    @referrers = apply_scopes(Referrer.scoped)
  end

end
