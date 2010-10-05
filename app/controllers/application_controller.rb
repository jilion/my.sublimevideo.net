class ApplicationController < ActionController::Base
  include CustomDevisePaths
  
  respond_to :html
  responders Responders::FlashResponder, Responders::PaginatedResponder, Responders::HttpCacheResponder
  
  layout 'application'
  
  before_filter :authenticate_user!
  
  protect_from_forgery
  
protected
  
  def public_release_only
    redirect_to sites_path unless MySublimeVideo::Release.public?
  end
  
  def authenticate_inviter!
    authenticate_admin!
  end
  
end