class Admin::SitesController < Admin::AdminController
  respond_to :html, except: [:videos_infos, :invoices, :active_pages]
  respond_to :js, only: [:index, :update, :generate_loader, :videos_infos, :invoices, :active_pages]

  before_filter do |controller|
    if action_name.in?(%w[update_app_design_subscription update_addon_plan_subscription])
      require_role?('god')
    end
  end
  before_filter :set_default_scopes, only: [:index]
  before_filter :find_site_by_token, only: [:edit, :update, :generate_loader, :videos_infos, :invoices, :active_pages, :update_app_design_subscription, :update_addon_plan_subscription]

  # filter & search
  has_scope :tagged_with, :with_state, :user_id, :search, :with_addon_plan
  has_scope :with_wildcard, :with_path, :with_extra_hostnames, :free, :paying, type: :boolean
  # sort
  has_scope :by_hostname, :by_user, :by_state, :by_last_30_days_billable_video_views, :by_last_30_days_video_tags, :by_last_30_days_extra_video_views_percentage,
            :by_date, :with_min_billable_video_views

  # GET /sites
  def index
    @sites = apply_scopes(Site.includes(:user, :billable_items))
    @tags  = Site.tag_counts.order { tags.name }

    respond_with(@sites, per_page: 50)
  end

  # GET /sites/:id
  def show
    redirect_to edit_admin_site_path(params[:id])
  end

  # GET /sites/:id/edit
  def edit
    @tags = Site.tag_counts.order { tags.name }

    respond_with(@site)
  end

  # PUT /sites/:id
  def update
    params[:site].delete(:accessible_stage) unless has_role?('god')
    @site.update_attributes(params[:site], without_protection: true)

    respond_with(@site, notice: 'Site has been successfully updated.', location: [:edit, :admin, @site]) do |format|
      format.js { render 'admin/shared/flash_update' }
    end
  end

  # PUT /sites/:id
  def generate_loader
    if params[:stage] == 'all'
      LoaderGenerator.delay.update_all_stages!(@site.id)
      CampfireWrapper.delay.post("Update all loaders for #{@site.hostname} (#{@site.token}).")
    else
      LoaderGenerator.delay.update_stage!(@site.id, params[:stage])
      CampfireWrapper.delay.post("Update #{params[:stage]} loader for #{@site.hostname} (#{@site.token}).")
    end

    respond_with(@site, notice: "#{params[:stage].titleize} loader(s) will be regenerated.", location: [:edit, :admin, @site]) do |format|
      format.js { render 'admin/shared/flash_update' }
    end
  end

  # GET /sites/:id/videos_infos
  def videos_infos
  end

  # GET /sites/:id/invoices
  def invoices
  end

  # GET /sites/:id/active_pages
  def active_pages
  end

  # PUT /sites/:id/update_app_design_subscription
  def update_app_design_subscription
    @app_design = App::Design.find(params[:app_design_id])

    options = { allow_custom: true }
    options[:force] = params[:state] if params[:state].present?
    design_subscriptions = { @app_design.name => (params[:state] == 'canceled' ? '0' : @app_design.id) }
    SiteManager.new(@site).update_billable_items(design_subscriptions, {}, options)

    notice = t('flash.sites.update_app_design_subscription.notice', app_design_title: @app_design.title, state: params[:state].presence || 'subscribed')
    respond_with(@site, notice: notice, location: [:edit, :admin, @site])
  end

  # PUT /sites/:id/update_addon_plan_subscription
  def update_addon_plan_subscription
    @addon_plan = AddonPlan.find(params[:addon_plan_id])

    options = { allow_custom: true }
    options[:force] = params[:state] if params[:state].present?
    addon_plan_subscriptions = { @addon_plan.addon.name => (params[:state] == 'canceled' ? '0' : @addon_plan.id) }
    SiteManager.new(@site).update_billable_items({}, addon_plan_subscriptions, options)

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

  def find_site_by_token
    @site = Site.find_by_token!(params[:id])
  end

end
