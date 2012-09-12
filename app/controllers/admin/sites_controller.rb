class Admin::SitesController < Admin::AdminController
  respond_to :js, :html

  before_filter { |controller| require_role?('god') if %w[sponsor].include?(action_name) }
  before_filter :set_default_scopes, only: [:index]

  #filter
  has_scope :in_plan, :badged, :tagged_with, :with_state, :user_id
  has_scope :in_trial, :not_in_trial, :in_paid_plan, :overusage_notified,
            :with_wildcard, :with_path, :with_extra_hostnames, :with_next_cycle_plan, type: :boolean
  # sort
  has_scope :by_hostname, :by_user, :by_state, :by_plan_price,
            :by_last_30_days_billable_video_views, :by_last_30_days_video_tags, :by_last_30_days_extra_video_views_percentage,
            :by_last_30_days_plan_usage_percentage, :by_date, :by_trial_started_at, :with_min_billable_video_views
  # search
  has_scope :search

  # GET /sites
  def index
    @sites = apply_scopes(Site.includes(:user, :plan))
    @tags  = Site.tag_counts.order{ tags.name }

    respond_with(@sites, per_page: 50)
  end

  # GET /sites/:id
  def show
    redirect_to edit_admin_site_path(params[:id])
  end

  # GET /sites/:id/edit
  def edit
    @site = Site.includes(:user).find_by_token!(params[:id])
    @tags = Site.tag_counts.order{ tags.name }

    respond_with(@site)
  end

  # PUT /sites/:id
  def update
    @site = Site.find_by_token!(params[:id])
    params[:site].delete(:mode) unless has_role?('god')
    @site.update_attributes(params[:site], without_protection: true)

    respond_with(@site, notice: 'Site was successfully updated.') do |format|
      format.js   { render 'admin/shared/flash_update' }
      format.html { redirect_to [:edit, :admin, @site] }
    end
  end

  # PUT /sites/:id/sponsor
  def sponsor
    @site = Site.find_by_token!(params[:id])
    @site.sponsor!

    respond_with(@site)
  end

  private

  def set_default_scopes
    params[:with_state] = 'active' if (scopes_configuration.keys & params.keys.map(&:to_sym)).empty?

    unless params.keys.any? { |k| k =~ /^by_\w+$/ }
      if params[:in_trial]
        params[:by_trial_started_at] = 'desc'
      else
        params[:by_date] = 'desc'
      end
    end
  end

end
