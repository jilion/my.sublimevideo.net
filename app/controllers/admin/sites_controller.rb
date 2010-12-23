class Admin::SitesController < Admin::AdminController
  respond_to :js, :html
  
  has_scope :with_activity, :type => :boolean
  # sort
  has_scope :by_hostname
  has_scope :by_user
  has_scope :by_state
  has_scope :by_loader_hits_cache
  has_scope :by_player_hits_cache
  has_scope :by_traffic
  has_scope :by_flash_percentage
  has_scope :by_loader_player_ratio
  has_scope :by_traffic_player_ratio
  has_scope :by_google_rank
  has_scope :by_alexa_rank
  has_scope :by_date
  # search
  has_scope :search
  
  # GET /admin/sites
  def index
    @sites = Site.includes(:user)
    @sites = @sites.not_archived unless params[:archived_included]
    @sites = apply_scopes(@sites).by_date
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
