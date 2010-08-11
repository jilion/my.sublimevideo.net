class PagesController < ApplicationController
  skip_before_filter :authenticate_user!
  before_filter :authenticate_suspended_user!, :if => proc { |c| params[:page] == 'suspended' }
  
  responders Responders::PageCacheResponder
  
  def show
    render params[:page]
  end
  
protected
  
  def authenticate_suspended_user!
    authenticate_user!
    redirect_to root_path if user_signed_in? && !current_user.suspended?
  end
  
end
