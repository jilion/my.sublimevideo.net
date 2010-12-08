class Admin::SitesController < Admin::AdminController
  respond_to :js, :html
  
  has_scope :by_hostname
  has_scope :by_user
  has_scope :by_state
  has_scope :by_google_rank
  has_scope :by_alexa_rank
  has_scope :by_date
  # search
  has_scope :search
  
  # GET /admin/sites
  def index
    @sites = Site.includes(:user)
    @sites = @sites.not_archived unless params[:archived_included]
    respond_with(apply_scopes(@sites).by_date)
  end
  
  # GET /admin/sites/1
  def show
    redirect_to edit_admin_site_path(params[:id])
  end
  
  # GET /admin/sites/1/edit
  def edit
    @site = Site.includes(:user).find_by_token(params[:id])
    respond_with(@site)
  end
  
  # PUT /admin/sites/1
  def update
    @site = Site.find_by_token(params[:id])
    @site.player_mode = params[:site][:player_mode]
    @site.save
    respond_with(@site, :location => [:admin, :sites])
  end
  
end
