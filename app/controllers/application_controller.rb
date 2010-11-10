class ApplicationController < ActionController::Base
  include CustomDevisePaths
  
  respond_to :html
  responders Responders::FlashResponder, Responders::PaginatedResponder, Responders::HttpCacheResponder, Responders::PasswordResponder
  
  layout 'application'
  
  before_filter :authenticate_user!
  
  protect_from_forgery
  
protected
  
  def user_for_paper_trail
    params[:user][:email].downcase! if params[:user] && params[:user][:email]
    current_user rescue nil
  end
  
  def info_for_paper_trail
    { :admin_id => current_admin_id, :ip => request.remote_ip, :user_agent => request.user_agent }
  end
  
  def current_admin_id
    current_admin.try(:id) rescue nil
  end
  
  def redirect_suspended_user
    redirect_to page_path('suspended') if current_user.suspended?
  end
  
  module DeviseInvitable::Controllers::Helpers
  protected
    def authenticate_inviter!
      authenticate_admin!
    end
  end
  
  
end