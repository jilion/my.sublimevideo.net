require 'digest/sha1'

class BetasController < ActionController::Base
  
  def show
  end
  
  def create
    session[:beta_key] = Digest::SHA1.hexdigest("sublime-#{params[:beta_key]}")
    redirect_to root_path
  end
  
end