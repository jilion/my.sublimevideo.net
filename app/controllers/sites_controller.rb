class SitesController < ApplicationController
  
  respond_to :html
  before_filter :authenticate_user!
  
  # GET /sites
  def index
    @sites = current_user.sites.all
    respond_with(@sites)
  end
  
  # GET /sites/1
  def show
    @site = current_user.sites.find(params[:id])
    respond_with(@site)
  end
  
  # GET /sites/new
  def new
    @site = current_user.sites.build
  end
  
  # GET /sites/1/edit
  def edit
    @site = current_user.sites.find(params[:id])
  end
  
  # POST /sites
  def create
    @site = current_user.sites.create(params[:site])
    respond_with(@site)
  end
  
  # PUT /sites/1
  def update
    @site = current_user.sites.find(params[:id])
    @site.update_attributes(params[:site])
    respond_with(@site)
  end
  
  # DELETE /sites/1
  def destroy
    @site = current_user.sites.find(params[:id])
    @site.destroy
    respond_with(@site)
  end
  
end