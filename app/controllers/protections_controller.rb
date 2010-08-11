require 'digest/sha1'

class ProtectionsController < ActionController::Base
  
  def show
  end
  
  def create
    session[:protection_key] = Digest::SHA1.hexdigest("sublime-#{params[:protection_key]}")
    redirect_to root_path
  end
  
end