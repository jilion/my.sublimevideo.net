class VideosController < ApplicationController
  before_filter :authenticate_user!, :except => :transcoded
  respond_to :html, :js
  
  has_scope :by_date
  has_scope :by_name
  
  # GET /videos
  def index
    @videos = apply_scopes(current_user.videos.includes(:formats), :default => { :by_date => 'desc' })
    respond_with(@videos)
  end
  
  # GET /videos/1
  def show
    @video = current_user.videos.find(params[:id])
    # @video_data = JSON.parse(Panda.get("/videos/#{@video.panda_id}.json"))
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
    respond_with(@video) do |format|
      format.html { redirect_to videos_path }
      format.js
    end
  end
  
  # GET /videos/d891d9a45c698d587831466f236c6c6c/transcoded - Notification url called by Panda
  def transcoded
    # We could check from where the notification comes from, maybe with something like request.remote_ip
    @video = VideoOriginal.find_by_panda_id!(params[:id])
    @video.activate
    # unless @video.active?
    #   # Check if all the formats of the given video are ready before actually activate the video
    #   video_formats_data = {} # JSON.parse(Panda.get("/videos/#{params[:id]}/encodings.json"))
    #   if video_formats_data.all? { |f| f.status == 'success' && f.encoding_progress == '100' }
    #     @video.activate
    #   end
    # end
    head :ok
  end
  
end