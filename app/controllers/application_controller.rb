class ApplicationController < ActionController::Base
  include CustomDevisePaths
  
  respond_to :html
  responders Responders::FlashResponder, Responders::PaginatedResponder, Responders::HttpCacheResponder
  
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
  
  def redirect_wrong_password(resource, password)
    unless current_user.valid_password?(password)
      flash[:alert] = "The given password is invalid!"
      Rails.logger.debug resource.class
      route = case resource.class.to_s
      when 'User'
        edit_user_registration_path
      else
        [:edit, resource]
      end
      redirect_to route and return
    end
  end
  
  module DeviseInvitable::Controllers::Helpers
  protected
    def authenticate_inviter!
      authenticate_admin!
    end
  end
  
end