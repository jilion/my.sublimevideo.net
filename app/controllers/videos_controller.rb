class VideosController < ApplicationController
  respond_to :html
  respond_to :js
  before_filter :authenticate_user!, :set_default_sort
  
  has_scope :by_date
  has_scope :by_name
  
  # GET /videos
  def index
    @videos = apply_scopes(current_user.videos.scoped)
    respond_with(@videos)
  end
  
  # GET /videos/1
  def show
    @video = current_user.videos.find(params[:id])
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
      else
        format.html do
          @videos = current_user.videos.scoped
          render :action => :index
        end
      end
    end
  end
  
  # PUT /videos/1
  def update
    @video = current_user.videos.find(params[:id])
    respond_with(@video) do |format|
      if @video.update_attributes(params[:video])
        format.html { redirect_to videos_path }
      else
        format.html do
          render :action => :edit
        end
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