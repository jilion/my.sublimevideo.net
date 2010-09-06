class Admin::SitesController < Admin::AdminController
  respond_to :js, :html
  
  # GET /admin/sites
  def index
    @sites = Site.includes(:user)
    respond_with(@sites)
  end
  
  # GET /admin/sites/1
  def show
    @site = Site.includes(:user).find(params[:id])
    respond_with(@site)
  end
  
  # GET /admin/sites/1/edit
  def edit
    @site = Site.includes(:user).find(params[:id])
    respond_with(@site)
  end
  
  # PUT /admin/sites/1
  def update
    @site = Site.find(params[:id])
    @site.player_mode = params[:site][:player_mode]
    respond_with(@site) do |format|
      if @site.save
        @site.deactivate # re-go to :pending state
        @site.delay.activate # re-generate license file
        format.html { redirect_to admin_site_path(@site) }
      else
        format.html { render :edit }
      end
    end
  end
  
end
