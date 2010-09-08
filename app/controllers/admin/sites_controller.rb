class Admin::SitesController < Admin::AdminController
  respond_to :js, :html
  
  has_scope :with_activity, :type => :boolean
  
  # GET /admin/sites
  def index
    @sites = apply_scopes(Site.includes(:user))
    respond_with(@sites)
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
        @site.delay.activate # re-generate license file
        format.html { redirect_to admin_sites_path }
      else
        format.html { render :edit }
      end
    end
  end
  
end
