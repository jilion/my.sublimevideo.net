class SitesController < ApplicationController
  respond_to :html
  respond_to :js, :json, only: [:index]

  before_filter :redirect_suspended_user
  before_filter :activate_deal_from_cookie, only: [:index, :new]
  before_filter :find_sites_or_redirect_to_new_site, only: [:index, :edit, :update, :destroy]
  before_filter :find_by_token!, only: [:edit, :update, :destroy]
  before_filter :set_current_plan, :set_custom_plan, only: [:new, :create]

  has_scope :by_hostname
  has_scope :by_date
  has_scope :by_last_30_days_billable_video_views

  # GET /sites
  def index
    load_usages_for_initial_help

    respond_with(@sites, per_page: 10) do |format|
      format.html
      format.js
      format.json { render json: @sites.to_backbone_json }
    end
  end

  # GET /sites/new
  def new
    @site = current_user.sites.build((params[:site] || {}).reverse_merge(dev_hostnames: Site::DEFAULT_DEV_DOMAINS))

    respond_with(@site)
  end

  # GET /sites/:id/edit
  def edit
    respond_with(@site)
  end

  # POST /sites
  def create
    params[:site][:remote_ip] = request.remote_ip
    params[:site][:plan_id]   = Plan.trial_plan.id if !params[:site_skip_trial] || !params[:site][:plan_id]
    @site = current_user.sites.build(params[:site])

    respond_with(@site) do |format|
      if @site.save # will create site (& create invoice and charge it if skip_trial is true)
        notice_and_alert = notice_and_alert_from_transaction(@site.last_transaction)
        format.html { redirect_to :sites, notice_and_alert }
      else
        flash[:notice] = flash[:alert] = ""
        format.html { render :new }
      end
    end
  end

  # PUT /sites/:id
  def update
    @site.update_attributes(params[:site])

    respond_with(@site, location: :sites)
  end

  # DELETE /sites/:id
  def destroy
    @site.user_attributes = params[:site] && params[:site][:user_attributes]

    respond_with(@site) do |format|
      if @site.archive
        format.html { redirect_to :sites }
      else
        format.html { render :edit }
      end
    end
  end

  private

  def activate_deal_from_cookie
    if cookies[:d]
      if deal = Deal.find_by_token(cookies[:d])
        deal_activation = current_user.deal_activations.build(deal_id: deal.id)
        if deal_activation.save
          cookies.delete :d, domain: :all
        end
      end
    end
  end

  def find_by_token!
    @site = current_user.sites.not_archived.find_by_token!(params[:id])
  end

  def load_usages_for_initial_help
    site_tokens = current_user.sites.not_archived.map(&:token)
    @billable_views = Stat::Site::Day.views_sum(token: site_tokens, billable_only: true)

    if @billable_views.zero?
      @loader_hits = SiteUsage.where(site_id: { "$in" => current_user.sites.not_archived.map(&:id) }).only(:loader_hits, :ssl_loader_hits).entries.sum { |s| s.loader_hits + s.ssl_loader_hits }
      @dev_views   = Stat::Site::Day.views_sum(token: site_tokens)
    end
  end

end
