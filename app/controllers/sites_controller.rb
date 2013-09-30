class SitesController < ApplicationController
  respond_to :html
  respond_to :json, only: [:index]

  before_filter :redirect_suspended_user
  before_filter :activate_deal_from_cookie, only: [:index]
  before_filter :_set_sites_or_redirect_to_new_site, except: [:new, :create]
  before_filter :_set_sites, only: [:new, :create]
  before_filter :_set_site, only: [:edit, :update, :destroy]

  etag { current_user.id }

  has_scope :by_hostname, :by_date, :by_last_30_days_starts, :by_last_30_days_video_tags

  # GET /sites
  def index
    @sites = apply_scopes(@sites.includes(:invoices).by_date)

    if stale?(last_modified: @sites.maximum(:updated_at), etag: @sites.to_sql)
      respond_with(@sites, per_page: 10) do |format|
        format.html
        format.json { render json: @sites.to_backbone_json }
      end
    end
  end

  # GET /sites/:id/edit
  def edit
    respond_with(@site) if stale?(@site)
  end

  # PUT /sites/:id
  def update
    SiteManager.new(@site).update(_site_params)

    respond_with(@site, location: [:edit, @site])
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

  def _site_params
    params.require(:site).permit(:hostname, :extra_hostnames, :staging_hostnames, :dev_hostnames, :path, :wildcard)
  end

end
