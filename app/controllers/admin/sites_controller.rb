class Admin::SitesController < Admin::AdminController
  respond_to :js, :html

  before_filter { |controller| require_role?('god') if %w[update sponsor].include?(action_name) }

  #filter
  has_scope :in_plan, :badged
  has_scope :in_trial, :not_in_trial, :paid_plan, :overusage_notified, :user_id, :with_wildcard, :with_path, :with_extra_hostnames, :with_next_cycle_plan, type: :boolean
  has_scope :with_state do |controller, scope, value|
    scope.with_state(value.to_sym)
  end
  # sort
  has_scope :by_hostname, :by_user, :by_state, :by_plan_price, :by_last_30_days_billable_video_views, :by_last_30_days_extra_video_views_percentage, :by_last_30_days_plan_usage_persentage, :by_date, :by_trial_started_at, :search

  # GET /sites
  def index
    @sites = Site.includes(:user, :plan)
    @sites = @sites.active if params[:with_state].nil?
    @sites = apply_scopes(@sites).send(params[:in_trial] ? :by_trial_started_at : :by_date)
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
