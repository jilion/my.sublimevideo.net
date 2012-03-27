class Admin::ReferrersController < AdminController
  respond_to :js, :html

  has_scope :by_hits
  has_scope :by_badge_hits
  has_scope :by_contextual_hits
  has_scope :by_updated_at
  has_scope :by_created_at

  # GET /referrers
  def index
    @referrers = Referrer.criteria
    %w[by_hits by_updated_at by_created_at by_contextual_hits by_badge_hits].each do |by|
      @referrers = @referrers.send(by.to_sym, params[by.to_sym]) if params[by.to_sym]
    end
    @referrers.by_created_at if @referrers.criteria.options[:sort].nil?
    respond_with(@referrers, per_page: 100)
  end

end
