class SitesController < ApplicationController
  respond_to :html, :js
  
  before_filter :redirect_suspended_user
  
  has_scope :by_hostname
  has_scope :by_date, :default => 'desc', :always => true do |controller, scope, value|
    controller.params.keys.any? { |k| k != "by_date" && k =~ /(by_\w+)/ } ? scope : scope.by_date(value)
  end
  
  # GET /sites
  def index
    @sites = apply_scopes(current_user.sites.not_archived)
    respond_with(@sites)
  end
  
  # GET /sites/1
  def show
    @site = current_user.sites.find(params[:id])
    respond_with(@site) do |format|
      format.html { redirect_to sites_path }
      format.js
    end
  end
  
  # GET /sites/new
  def new
    @site = current_user.sites.build
    respond_with(@site) do |format|
      format.html { redirect_to sites_path }
      format.js
    end
  end
  
  # GET /sites/1/edit
  def edit
    @site = current_user.sites.find(params[:id])
    respond_with(@site) do |format|
      format.html { redirect_to sites_path }
      format.js
    end
  end
  
  # GET /sites/1/state
  def state
    @site = current_user.sites.find(params[:id])
    respond_with(@site) do |format|
      format.js   { head :ok unless @site.active? }
      format.html { redirect_to sites_path }
    end
  end
  
  # POST /sites
  def create
    @site = current_user.sites.build(params[:site])
    respond_with(@site) do |format|
      if @site.save
        @site.delay.activate
        format.html { redirect_to sites_path }
        format.js
      else
        format.html { redirect_to sites_path }
        format.js   { render :new }
      end
    end
  end
  
  # PUT /sites/1
  def update
    @site = current_user.sites.find(params[:id])
    respond_with(@site) do |format|
      if @site.update_attributes(params[:site])
        @site.delay.activate # re-generate license file
        format.html { redirect_to sites_path }
        format.js
      else
        format.html { redirect_to sites_path }
        format.js   { render :edit }
      end
    end
  end
  
  # DELETE /sites/1
  def destroy
    @site = current_user.sites.find(params[:id])
    @site.archive
    respond_with(@site) do |format|
      format.html { redirect_to sites_path }
    end
  end
  
protected
  
  def redirect_suspended_user
    redirect_to page_path('suspended') if current_user.suspended?
  end
  
end