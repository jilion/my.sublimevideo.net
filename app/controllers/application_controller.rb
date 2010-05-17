class ApplicationController < ActionController::Base
  protect_from_forgery
  responders Responders::FlashResponder, Responders::HttpCacheResponder
  
  layout 'application'
  before_filter :beta_protection
  
protected
  
  def beta_protection
    if Rails.env.production? || Rails.env.staging?
      redirect_to beta_path unless session[:beta_key] == 'sublime33'
    end
  end
  
end