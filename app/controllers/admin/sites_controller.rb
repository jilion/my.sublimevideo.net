class Admin::SitesController < Admin::AdminController
  respond_to :js, :html

  before_filter { |controller| require_role?('god') if %w[update sponsor].include?(action_name) }

  #filter
  has_scope :in_plan, :badged, :tagged_with
  has_scope :in_trial, :not_in_trial, :paid_plan, :overusage_notified, :user_id,
            :with_wildcard, :with_path, :with_extra_hostnames, :with_next_cycle_plan, type: :boolean
  has_scope(:with_state) { |controller, scope, value| scope.with_state(value.to_sym) }
  # sort
  has_scope :by_hostname, :by_user, :by_state, :by_plan_price,
            :by_last_30_days_billable_video_views, :by_last_30_days_extra_video_views_percentage,
            :by_last_30_days_plan_usage_persentage, :by_date, :by_trial_started_at
  # search
  has_scope :search

  # GET /sites
  def index
    @sites = Site.includes(:user, :plan)
    @sites = @sites.active if params[:with_state].nil?
    params[:by_date] = 'desc' unless params[:by_date]
    @sites = apply_scopes(@sites)
    @tags  = Site.tag_counts

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
    @site.player_mode = params[:site][:player_mode] if params[:site][:player_mode]
    @site.tag_list    = params[:site][:tag_list] if params[:site][:tag_list]
    @site.save!

    respond_with(@site)
  end

  # PUT /sites/:id/sponsor
  def sponsor
    @site = Site.find_by_token(params[:id])
    @site.sponsor!

    respond_with(@site)
  end

  def autocomplete_tag_list
    @word = params[:word]
    match = "%#{@word}%"
    @tags = Site.tag_counts_on(:tags).where { lower(:name) =~ lower(match) }.order(:name).limit(10)

    render '/admin/shared/autocomplete_tag_list'
  end

end
