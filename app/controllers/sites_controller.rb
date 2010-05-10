class SitesController < ApplicationController
  respond_to :html
  
  # GET /sites
  def index
    @sites = Site.all
    respond_with(@sites)
  end
  
  # GET /sites/1
  def show
    @site = Site.find(params[:id])
    respond_with(@site)
  end
  
  # GET /sites/new
  def new
    @site = Site.new
  end
  
  # GET /sites/1/edit
  def edit
    @site = Site.find(params[:id])
  end
  
  # POST /sites
  def create
    @site = Site.create(params[:site])
    respond_with(@site)
  end
  
  # PUT /sites/1
  def update
    @site = Site.find(params[:id])
    @site.update_attributes(params[:site])
    respond_with(@site)
  end
  
  # DELETE /sites/1
  def destroy
    @site = Site.find(params[:id])
    @site.destroy
    respond_with(@site)
  end
  
end