class Admin::VideoProfilesController < Admin::AdminController
  
  # GET /admin/profiles
  def index
    @profiles = VideoProfile.includes(:versions)
    respond_with(@profiles)
  end
  
  # GET /admin/profiles/1
  def show
    @profile = VideoProfile.find(params[:id])
    @versions = @profile.versions.order(:created_at.desc)
    respond_with(@profile)
  end
  
  # GET /admin/profiles/new
  def new
    @profile = VideoProfile.new
    respond_with(@profile)
  end
  
  # GET /admin/profiles/1/edit
  def edit
    @profile = VideoProfile.find(params[:id])
    respond_with(@profile)
  end
  
  # POST /admin/profiles
  def create
    @profile = VideoProfile.new(params[:video_profile])
    respond_with(@profile) do |format|
      if @profile.save
        format.html { redirect_to admin_profiles_path }
      else
        format.html { render :new }
      end
    end
  end
  
  # PUT /admin/profiles/1
  def update
    @profile = VideoProfile.find(params[:id])
    respond_with(@profile) do |format|
      if @profile.update_attributes(params[:video_profile])
        format.html { redirect_to admin_profiles_path }
      else
        format.html { render :edit }
      end
    end
  end
  
end