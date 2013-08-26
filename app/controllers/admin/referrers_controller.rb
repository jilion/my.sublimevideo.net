class Admin::ReferrersController < Admin::AdminController
  respond_to :js, :html
  before_filter :_set_default_scope, :_set_referrers

  has_scope :by_hits, :by_updated_at

  # GET /referrers/pages
  def pages
    respond_with(@referrers, paginate: true)
  end

  private

  def _set_default_scope
    params[:by_updated_at] = 'desc' if (scopes_configuration.keys & params.keys.map(&:to_sym)).empty?
  end

  def _set_referrers
    @referrers = apply_scopes(Referrer.all)
  end
end
