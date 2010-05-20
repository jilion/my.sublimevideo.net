class VideosController < ApplicationController
  respond_to :html, :js
  before_filter :authenticate_user!, :set_default_sort
  
  has_scope :by_date
  has_scope :by_name
  
  # GET /videos
  def index
    @videos = apply_scopes(current_user.videos.includes(:formats))
    respond_with(@videos)
  end
  
  # GET /videos/1
  def show
    @video = current_user.videos.find(params[:id])
    # @video_data = JSON.parse(Panda.get("/videos/#{@video.panda_video_id}.json"))
    respond_with(@video)
  end
  
  # GET /videos/new
  def new
    @video = current_user.videos.build
    respond_with(@video)
  end
  
  # GET /videos/1/edit
  def edit
    @video = current_user.videos.find(params[:id])
  end
  
  # POST /videos
  def create
    @video = current_user.videos.build(params[:video])
    respond_with(@video) do |format|
      if @video.save
        # @video has been uploaded to Panda, now let's encode!
        # @video.delay.encode
        format.html { redirect_to videos_path }
        format.js
      else
        format.html { render :new }
        format.js   { render :new }
      end
    end
  end
  
  # PUT /videos/1
  def update
    @video = current_user.videos.find(params[:id])
    respond_with(@video) do |format|
      if @video.update_attributes(params[:video])
        format.html { redirect_to videos_path }
        format.js
      else
        format.html { render :edit }
        format.js   { render :edit }
      end
    end
  end
  
  # DELETE /videos/1
  def destroy
    @video = current_user.videos.find(params[:id])
    @video.destroy
    respond_with(@video)
  end
  
protected
  
  def set_default_sort
    params[:by_date] = 'desc' unless params[:by_date] || params[:by_name]
  end
  
end