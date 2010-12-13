class SitesController < ApplicationController
  respond_to :html
  respond_to :js, :only => [:index, :code, :new]
  
  before_filter :redirect_suspended_user
  before_filter :find_by_token, :only => [:code, :transition, :edit, :update, :activate, :destroy, :usage]
  before_filter :redirect_wrong_password_for_active_site!, :only => [:update, :activate, :destroy]
  
  has_scope :by_hostname
  has_scope :by_date
  
  # GET /sites
  def index
    @sites = apply_scopes(current_user.sites.not_archived.with_plan.with_addons.by_date)
    respond_with(@sites)
  end
  
  # GET /sites/1/code
  def code
    respond_with(@site) do |format|
      format.js
      format.html { redirect_to :sites }
    end
  end
  
  # GET /sites/new
  def new
    @site = current_user.sites.build((params[:site] || {}).reverse_merge(:dev_hostnames => Site::DEFAULT_DEV_DOMAINS))
    respond_with(@site)
  end
  
  # GET /sites/1/transition
  def transition
    respond_with(@site)
  end
  
  # GET /sites/1/edit
  def edit
    respond_with(@site) do |format|
      if @site.beta?
        format.html { redirect_to transition_site_path(@site.to_param) }
      else
        format.html
      end
    end
  end
  
  # POST /sites
  def create
    @site = current_user.sites.create(params[:site])
    respond_with(@site, :location => :sites)
  end
  
  # PUT /sites/1
  def update
    @site.update_attributes(params[:site])
    respond_with(@site, :location => :sites)
  end
  
  # PUT /sites/1/activate
  def activate
    @site.activate
    respond_with(@site, :location => :sites) do |format|
      unless current_user.cc?
        format.html { redirect_to [:edit, :credit_card], :notice => t("activerecord.errors.models.site.attributes.base.credit_card_needed") }
      end
    end
  end
  
  # DELETE /sites/1
  def destroy
    @site.archive
    respond_with(@site, :location => :sites)
  end
  
  # GET /sites/1/state
  def state
    @site = current_user.sites.find(params[:id])
    respond_with(@site) do |format|
      format.js
      format.html { redirect_to :sites }
    end
  end
  
  # GET /sites/1/usage
  def usage
    respond_with(@site) do |format|
      format.js
      format.html { redirect_to :sites }
    end
  end
  
private
  
  def find_by_token
    @site = current_user.sites.find_by_token(params[:id])
  end
  
  def redirect_wrong_password_for_active_site!
    redirect_wrong_password(@site) if @site.active?
  end
  
end