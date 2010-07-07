class EnthusiastsController < ApplicationController
  before_filter :require_no_authentication
  layout 'enthusiast'
  
  def new
    @enthusiast = Enthusiast.new
  end
  
  def create
    @enthusiast = Enthusiast.new(params[:enthusiast])
    if @enthusiast.save
      flash[:notice] = "Thanks! You will be notified..."
      redirect_to root_path
    else
      render :new
    end
  end
  
protected
  
  def require_no_authentication
    redirect_to sites_path if user_signed_in?
  end
  
end