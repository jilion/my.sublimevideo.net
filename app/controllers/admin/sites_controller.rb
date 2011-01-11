class Admin::SitesController < Admin::AdminController
  respond_to :js, :html

  before_filter :compute_date_range, :only => :edit

  #filter
  has_scope :next_plan_recommended_alert_sent_at_alerted_this_month
  has_scope :with_state do |controller, scope, value|
    scope.with_state(value.to_sym)
  end
  has_scope :with_wildcard
  has_scope :with_path
  # sort
  has_scope :by_hostname
  has_scope :by_user
  has_scope :by_state
  has_scope :by_google_rank
  has_scope :by_alexa_rank
  has_scope :by_date
  # search
  has_scope :search

  # GET /admin/sites
  def index
    @sites = Site.includes(:user)
    if params.keys.all? { |k| k =~ /^by_/ || %w[action controller search].include?(k) }
      @sites = @sites.not_archived
    end
    @sites = apply_scopes(@sites).by_date
    respond_with(@sites)
  end

  # GET /admin/sites/:id
  def show
    redirect_to edit_admin_site_path(params[:id])
  end

  # GET /admin/sites/:id/edit
  def edit
    @site = Site.includes(:user).find_by_token(params[:id])
    respond_with(@site)
  end

  # PUT /admin/sites/:id
  def update
    @site = Site.find_by_token(params[:id])
    @site.player_mode = params[:site][:player_mode]
    @site.save
    respond_with(@site, :location => [:admin, :sites])
  end

end
