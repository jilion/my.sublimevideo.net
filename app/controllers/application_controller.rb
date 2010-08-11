require 'digest/sha1'

class ApplicationController < ActionController::Base
  include CustomDevisePaths
  
  protect_from_forgery
  
  respond_to :html
  responders Responders::FlashResponder, Responders::PaginatedResponder, Responders::HttpCacheResponder
  
  layout 'application'
  
  before_filter :beta_protection
  before_filter :authenticate_user!
  
protected
  
  def beta_protection
    if Rails.env.production? || Rails.env.staging?
      beta_key = 'video66'
      redirect_to beta_path unless session[:beta_key] == Digest::SHA1.hexdigest("sublime-#{beta_key}")
    end
  end
  
  def public_required
    redirect_to sites_path unless MySublimeVideo::Release.public?
  end
  
  module DeviseInvitable::Controllers::Helpers
  protected
    def authenticate_inviter!
      authenticate_admin!
    end
  end
  
end