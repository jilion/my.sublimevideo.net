class SitesController < ApplicationController
  respond_to :html
  respond_to :js, :only => [:index, :show]
  
  before_filter :redirect_suspended_user
  before_filter :find_by_token, :only => [:show, :edit, :update, :destroy]
  before_filter :redirect_wrong_password_for_active_site!, :only => [:update, :destroy]
  
  has_scope :by_hostname
  has_scope :by_date
  
  # GET /sites
  def index
    respond_with(@sites = apply_scopes(current_user.sites.not_archived.with_plan.with_addons.by_date))
  end
  
  # GET /sites/1
  def show
    respond_with(@site) do |format|
      format.html { redirect_to sites_path }
      format.js
    end
  end
  
  # GET /sites/new
  def new
    respond_with(@site = current_user.sites.build(:dev_hostnames => Site::DEFAULT_DEV_DOMAINS))
  end
  
  # GET /sites/1/edit
  def edit
    respond_with(@site)
  end
  
  # POST /sites
  def create
    respond_with(@site = current_user.sites.create(params[:site]), :location => sites_path)
  end
  
  # PUT /sites/1
  def update
    @site.update_attributes(params[:site])
    respond_with(@site, :location => sites_path)
  end
  
  # DELETE /sites/1
  def destroy
    @site.archive
    respond_with(@site, :location => sites_path)
  end
  
  # GET /sites/1/state
  def state
    respond_with(@site = current_user.sites.find(params[:id])) do |format|
      format.js   { head :ok unless @site.cdn_up_to_date? }
      format.html { redirect_to sites_path }
    end
  end
  
private
  
  def find_by_token
    @site = current_user.sites.find_by_token(params[:id])
  end
  
  def redirect_wrong_password_for_active_site!
    redirect_wrong_password(@site, params[:current_password]) if @site.active?
  end
  
end