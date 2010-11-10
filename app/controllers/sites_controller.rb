class SitesController < ApplicationController
  respond_to :html
  respond_to :js, :only => [:index, :show]
  
  before_filter :redirect_suspended_user
  before_filter :find_by_token, :only => [:show, :edit, :update, :destroy, :stats]
  
  has_scope :by_hostname
  has_scope :by_date
  
  # GET /sites
  def index
    @sites = apply_scopes(current_user.sites.not_archived.with_plan.with_addons.by_date)
    respond_with(@sites)
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
    @site = current_user.sites.build(:dev_hostnames => Site::DEFAULT_DEV_DOMAINS)
    respond_with(@site)
  end
  
  # GET /sites/1/edit
  def edit
    respond_with(@site)
  end
  
  # POST /sites
  def create
    @site = current_user.sites.build(params[:site])
    respond_with(@site) do |format|
      if @site.save
        format.html { redirect_to sites_path }
      else
        format.html { render :new }
      end
    end
  end
  
  # PUT /sites/1
  def update
    @site.attributes = params[:site]
    valid_password_flash
    respond_with(@site, :flash => valid_password?) do |format|
      if @site.valid? && valid_password? && @site.save
        format.html { redirect_to sites_path }
      else
        format.html { render :edit }
      end
    end
  end
  
  # DELETE /sites/1
  def destroy
    valid_password_flash
    @site.archive if valid_password?
    respond_with(@site) do |format|
      format.html { redirect_to sites_path }
    end
  end
  
  # GET /sites/1/state
  def state
    @site = current_user.sites.find(params[:id])
    respond_with(@site) do |format|
      format.js   { head :ok unless @site.cdn_up_to_date? }
      format.html { redirect_to sites_path }
    end
  end
  
  # GET /sites/1/stats
  def stats
    respond_with(@site) do |format|
      format.js
      format.html { redirect_to sites_path }
    end
  end
  
private
  
  def find_by_token
    @site = current_user.sites.find_by_token(params[:id])
  end
  
  def valid_password?
    @valid_password ||= !@site.active? || (params[:password] && current_user.valid_password?(params[:password]))
  end
  
  def valid_password_flash
    flash[:alert] = "Your password is needed for this action!" unless valid_password?
  end
  
end