class Admin::ReleasesController < Admin::AdminController
  
  # GET /admin/releases
  def index
  end
  
  # POST /admin/releases
  def create
    @release = Release.new(params[:release])
    respond_with(@release) do |format|
      if @release.save
        format.html { redirect_to admin_releases_path }
      else
        format.html { render :index }
      end
    end
  end
  
  # PUT /admin/releases/:id
  def update
    @release = Release.find(params[:id])
    respond_with(@release) do |format|
      if @release.flag
        format.html { redirect_to admin_releases_path }
      else
        format.html { render :index }
      end
    end
  end
  
end