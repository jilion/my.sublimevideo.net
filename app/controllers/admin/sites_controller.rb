class Admin::SitesController < Admin::AdminController

  # GET /admin/sites
  def index
    @sites = Site.scoped
    respond_with(@sites)
  end
  
  # GET /admin/sites/1
  def show
    @site = Site.find(params[:id])
    respond_with(@site)
  end
  
end
