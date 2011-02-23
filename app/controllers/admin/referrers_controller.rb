class Admin::ReferrersController < Admin::AdminController
  respond_to :js, :html

  has_scope :by_url
  has_scope :by_hits
  has_scope :by_contextual_hits
  has_scope :by_updated_at
  has_scope :by_created_at

  # GET /admin/referrers
  def index
    @referrers = Referrer.criteria
    %w[by_url by_hits by_updated_at by_created_at by_contextual_hits].each do |by|
      @referrers = @referrers.send(by.to_sym, params[by.to_sym]) if params[by.to_sym]
    end
    @referrers.by_created_at if @referrers.scoped[:order_by].nil?
    respond_with(@referrers, :per_page => 100)
  end

end
