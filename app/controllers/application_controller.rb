require 'digest/sha1'

class ApplicationController < ActionController::Base
  include CustomDevisePaths
  
  respond_to :html
  
  protect_from_forgery
  responders Responders::FlashResponder, Responders::PaginatedResponder #, Responders::HttpCacheResponder
  
  layout 'application'
  before_filter :beta_protection
  
protected
  
  def beta_protection
    if Rails.env.production? || Rails.env.staging?
      beta_key = 'video66'
      redirect_to beta_path unless session[:beta_key] == Digest::SHA1.hexdigest("sublime-#{beta_key}")
    end
  end
  
end