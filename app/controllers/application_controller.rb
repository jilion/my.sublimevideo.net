class ApplicationController < ActionController::Base
  respond_to :html
  
  protect_from_forgery
  responders Responders::FlashResponder, Responders::PaginatedResponder #, Responders::HttpCacheResponder
  
  layout 'application'
  before_filter :beta_protection
  
protected
  
  def beta_protection
    if Rails.env.production? || Rails.env.staging?
      redirect_to beta_path unless session[:beta_key] == 'sublime33'
    end
  end
  
  # def after_update_path_for(resource_or_scope)
  #   edit_user_registration_path
  # end
  
  def after_sign_in_path_for(resource_or_scope)
    sites_path
  end
  
  def after_sign_out_path_for(resource_or_scope)
    new_user_session_path
  end
  
end