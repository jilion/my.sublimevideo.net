require_dependency 'service/site'

class Admin::SitesController < Admin::AdminController
  respond_to :js, :html

  before_filter { |controller| require_role?('god') if action_name =~ /update/ }
  before_filter :set_default_scopes, only: [:index]

  # filter & search
  has_scope :tagged_with, :with_state, :user_id, :search
  has_scope :with_wildcard, :with_path, :with_extra_hostnames, :free, :paying, type: :boolean
  # sort
  has_scope :by_hostname, :by_user, :by_state, :by_last_30_days_billable_video_views, :by_last_30_days_video_tags, :by_last_30_days_extra_video_views_percentage,
            :by_date, :with_min_billable_video_views

  # GET /sites
  def index
    @sites = apply_scopes(Site.includes(:user))
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
    @site.update_attributes(params[:site], without_protection: true)

    respond_with(@site, notice: 'Site has been successfully updated.', location: [:edit, :admin, @site]) do |format|
      format.js   { render 'admin/shared/flash_update' }
    end
  end

  # PUT /sites/:id/update_app_design_subscription
  def update_app_design_subscription
    @site       = Site.find_by_token!(params[:id])
    @app_design = App::Design.find(params[:app_design_id])

    app_design_new_subscription_hash = { @app_design.name => (params[:state] == 'canceled' ? '0' : @app_design.id) }
    options = params[:state].present? ? { force: params[:state] } : {}
    Service::Site.new(@site).update_billable_items(app_design_new_subscription_hash, {}, options)

    notice = t('flash.sites.update_app_design_subscription.notice', app_design_title: @app_design.title, state: params[:state].presence || 'subscribed')
    respond_with(@site, notice: notice, location: [:edit, :admin, @site])
  end

  # PUT /sites/:id/update_addon_plan_subscription
  def update_addon_plan_subscription
    @site       = Site.find_by_token!(params[:id])
    @addon_plan = AddonPlan.find(params[:addon_plan_id])

    if params[:state] == 'canceled'
      @site.billable_items.addon_plans.where(item_id: params[:addon_plan_id]).destroy_all
    else
      options = params[:state].present? ? { force: params[:state] } : {}
      Service::Site.new(@site).update_billable_items({}, { addon: params[:addon_plan_id] }, options)
    end

    notice = t('flash.sites.update_addon_plan_subscription.notice', addon_plan_title: @addon_plan.title, state: params[:state].presence || 'subscribed')
    respond_with(@site, notice: notice, location: [:edit, :admin, @site])
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
