class BetasController < ActionController::Base
  
  def show
  end
  
  def create
    session[:beta_key] = params[:beta_key]
    redirect_to root_path
  end
  
end