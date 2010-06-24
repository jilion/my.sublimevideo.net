class Admin::VideoProfileVersionsController < Admin::AdminController
  before_filter :find_profile
  
  # GET /admin/profiles/1/versions/1
  def show
    @version = @profile.versions.find(params[:id])
    @panda_profile_info = Transcoder.get(:profile, @version.panda_profile_id)
    respond_with(@version)
  end
  
  # GET /admin/profiles/1/versions/new
  def new
    @version = @profile.versions.build
    respond_with(@version)
  end
  
  # POST /admin/profiles/1/versions
  def create
    @version = @profile.versions.build(params[:video_profile_version])
    respond_with(@version) do |format|
      if @version.pandize
        format.html { redirect_to admin_profile_path(@profile) }
      else
        format.html { render :new }
      end
    end
  end
  
  # PUT /admin/profiles/1/versions/1
  def update
    @version = @profile.versions.find(params[:id])
    respond_with(@version) do |format|
      if @version.activate
        format.html { redirect_to admin_profile_path(@profile) }
      else
        format.html { render :edit }
      end
    end
  end
  
protected
  
  def find_profile
    @profile = VideoProfile.find(params[:profile_id])
  end
  
end