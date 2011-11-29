class Admin::SitesController < AdminController
  respond_to :js, :html

  #filter
  has_scope :free, type: :boolean
  has_scope :sponsored, type: :boolean
  has_scope :in_paid_plan, type: :boolean
  has_scope :with_state do |controller, scope, value|
    scope.with_state(value.to_sym)
  end
  has_scope :with_wildcard, type: :boolean
  has_scope :with_path, type: :boolean
  has_scope :with_extra_hostnames, type: :boolean
  has_scope :badged
  has_scope :billable do |controller, scope|
    scope.billable
  end
  has_scope :not_billable do |controller, scope|
    scope.not_billable
  end
  has_scope :overusage_notified, type: :boolean
  has_scope :user_id, type: :boolean
  has_scope :with_next_cycle_plan, type: :boolean

  # sort
  has_scope :by_hostname
  has_scope :by_user
  has_scope :by_state
  has_scope :by_plan_price
  has_scope :by_last_30_days_billable_video_views
  has_scope :by_last_30_days_extra_video_views_percentage
  has_scope :by_last_30_days_plan_usage_persentage
  has_scope :by_date
  # search
  has_scope :search

  # GET /sites
  def index
    @sites = Site.includes(:user, :plan)
    @sites = @sites.not_archived if params[:with_state].nil?
    @sites = apply_scopes(@sites).by_date
    respond_with(@sites, per_page: 50)
  end

  # GET /sites/:id
  def show
    redirect_to edit_admin_site_path(params[:id])
  end

  # GET /sites/:id/edit
  def edit
    @site = Site.includes(:user).find_by_token(params[:id])
    respond_with(@site)
  end

  # PUT /sites/:id
  def update
    @site = Site.find_by_token(params[:id])
    @site.player_mode = params[:site][:player_mode]
    @site.save
    respond_with(@site, location: [:admin, :sites])
  end

  # PUT /sites/:id/sponsor
  def sponsor
    @site = Site.find_by_token(params[:id])
    @site.sponsor!
    respond_with(@site, location: [:admin, @site])
  end

end
