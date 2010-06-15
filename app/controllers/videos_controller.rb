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
    @video = current_user.videos.build
    @video.panda_video_id = params[:video][:panda_video_id]
    
    respond_with(@video) do |format|
      if @video.save
        @video.delay.pandize
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
  
  # GET /videos/d891d9a45c698d587831466f236c6c6c/transcoded - Notification url called by Panda, should be a POST
  def transcoded
    @video_encoding = VideoEncoding.find_by_panda_encoding_id!(params[:id])
    @video_encoding.delay.activate
    head :ok
  end
  
end