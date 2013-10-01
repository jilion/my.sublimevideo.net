class Admin::SitesController < Admin::AdminController
  respond_to :html, except: [:more_info, :invoices, :active_pages]
  respond_to :js, only: [:index, :update, :generate_loader, :generate_settings, :more_info, :invoices, :active_pages]

  before_filter do |controller|
    if action_name.in?(%w[update_design_subscription update_addon_plan_subscription])
      require_role?('god')
    end
  end
  before_filter :_set_default_scopes, only: [:index]
  before_filter :_set_site, only: [:edit, :update, :generate_loader, :generate_settings, :more_info, :invoices, :active_pages, :update_design_subscription, :update_addon_plan_subscription]

  # filter & search
  has_scope :tagged_with, :with_state, :user_id, :search, :with_addon_plan
  has_scope :with_wildcard, :with_path, :with_extra_hostnames, :free, :paying, type: :boolean
  # sort
  has_scope :by_hostname, :by_user, :by_state, :by_last_30_days_admin_starts, :by_last_30_days_video_tags, :by_date, :with_min_admin_starts

  # GET /sites
  def index
    @sites = apply_scopes(Site.includes(:user))
    @tags  = Site.tag_counts.order('tags.name')

    respond_with(@sites, per_page: 50)
  end

  # GET /sites/:id
  def show
    redirect_to edit_admin_site_path(params[:id])
  end

  # GET /sites/:id/edit
  def edit
    @tags = Site.tag_counts.order('tags.name')

    respond_with(@site)
  end

  # PUT /sites/:id
  def update
    params[:site].delete(:accessible_stage) unless has_role?('god')
    @site.update(_site_params)

    _respond_for_site_with_notice('Site has been successfully updated.')
  end

  # PUT /sites/:id/generate_loader
  def generate_loader
    if params[:stage] == 'all'
      LoaderGenerator.delay(queue: 'my').update_all_stages!(@site.id)
      CampfireWrapper.delay(queue: 'my').post("Update all loaders for #{@site.hostname} (#{@site.token}).")
    else
      LoaderGenerator.delay(queue: 'my').update_stage!(@site.id, params[:stage])
      CampfireWrapper.delay(queue: 'my').post("Update #{params[:stage]} loader for #{@site.hostname} (#{@site.token}).")
    end

    _respond_for_site_with_notice("#{params[:stage].titleize} loader(s) will be regenerated.")
  end

  # PUT /sites/:id/generate_settings
  def generate_settings
    SettingsGenerator.delay(queue: 'my').update_all!(@site.id)
    CampfireWrapper.delay(queue: 'my').post("Update settings for #{@site.hostname} (#{@site.token}).")

    _respond_for_site_with_notice('Settings will be regenerated.')
  end

  # GET /sites/:id/more_info
  def more_info
  end

  # GET /sites/:id/invoices
  def invoices
  end

  # GET /sites/:id/active_pages
  def active_pages
  end

  # PATCH /sites/:id/update_design_subscription
  def update_design_subscription
    _update_billable_item_subscription('design')
  end

  # PATCH /sites/:id/update_addon_plan_subscription
  def update_addon_plan_subscription
    _update_billable_item_subscription('addon_plan')
  end

  private

  def _update_billable_item_subscription(type)
    @item = type.classify.constantize.find(params[:"#{type}_id"])
    send("_update_#{type}_subscription", @item)

    _respond_for_site_with_notice(t("flash.sites.update_#{type}_subscription.notice", :"#{type}_title" => @item.title, state: params[:state].presence || 'subscribed'))
  end

  def _set_default_scopes
    params[:with_state] = 'active' if (scopes_configuration.keys & params.keys.map(&:to_sym)).empty?

    unless params.keys.any? { |k| k =~ /^by_\w+$/ }
      if params[:in_trial]
        params[:by_trial_started_at] = 'desc'
      else
        params[:by_date] = 'desc'
      end
    end
  end

  def _set_site
    @site = Site.where(token: params[:id]).first!
  end

  def _site_params
    params.require(:site).permit!
  end

  def _update_design_subscription(design)
    options = { allow_custom: true, force: params[:state].presence || false }
    design_subscriptions = { design.name => (params[:state] == 'canceled' ? '0' : design.id) }
    SiteManager.new(@site).update_billable_items(design_subscriptions, {}, options)
  end

  def _update_addon_plan_subscription(addon_plan)
    options = { allow_custom: true, force: params[:state].presence || false }
    addon_plan_subscriptions = { addon_plan.addon_name => (params[:state] == 'canceled' ? '0' : addon_plan.id) }
    SiteManager.new(@site).update_billable_items({}, addon_plan_subscriptions, options)
  end

  def _respond_for_site_with_notice(text)
    respond_with(@site, notice: text, location: [:edit, :admin, @site]) do |format|
      format.js { render 'admin/shared/flash_update' }
    end
  end

end
