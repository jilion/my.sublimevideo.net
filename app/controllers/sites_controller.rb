require_dependency 'sites/site_manager'

class SitesController < ApplicationController
  respond_to :html
  respond_to :js, :json, only: [:index]

  before_filter :redirect_suspended_user
  before_filter :activate_deal_from_cookie, only: [:index, :new]
  before_filter :find_sites_or_redirect_to_new_site, only: [:index, :edit, :update, :destroy]
  before_filter :find_site_by_token!, only: [:edit, :update, :destroy]

  has_scope :by_hostname, :by_date, :by_last_30_days_billable_video_views, :by_last_30_days_video_tags

  # GET /sites
  def index
    @sites = @sites.includes(:invoices)
    @sites = apply_scopes(@sites).by_date

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
    @site = Site.new(params[:site])

    respond_with(@site) do |format|
      if Sites::SiteManager.new(@site).create(current_user)
        format.html { redirect_to :sites }
      else
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

end
