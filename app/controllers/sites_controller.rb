class SitesController < ApplicationController
  respond_to :html
  respond_to :js, :only => :show
  before_filter :authenticate_user!
  
  # GET /sites
  def index
    @sites = current_user.sites.scoped
    respond_with(@sites)
  end
  
  # GET /sites/1
  def show
    @site = current_user.sites.find(params[:id])
    respond_with(@site)
  end
  
  # GET /sites/1/edit
  def edit
    @site = current_user.sites.find(params[:id])
  end
  
  # POST /sites
  def create
    @site = current_user.sites.build(params[:site])
    respond_with(@site) do |format|
      if @site.save
        @site.activate
        format.html { redirect_to sites_path }
      else
        format.html do
          @sites = current_user.sites.scoped
          render :action => :index
        end
      end
    end
  end
  
  # PUT /sites/1
  def update
    @site = current_user.sites.find(params[:id])
    respond_with(@site) do |format|
      if @site.update_attributes(params[:site])
        @site.deactivate # re-go to :pending state
        @site.activate # re-generate license file
        format.html { redirect_to sites_path }
      else
        format.html do
          render :action => :edit
        end
      end
    end
  end
  
  # DELETE /sites/1
  def destroy
    @site = current_user.sites.find(params[:id])
    @site.destroy
    respond_with(@site)
  end
  
end