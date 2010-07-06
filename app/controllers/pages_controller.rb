class PagesController < ApplicationController
  before_filter :authenticate_suspended_user!
  
  def show
    render params[:page]
  end
  
protected
  
  def authenticate_suspended_user!
    if params[:page] == 'suspended'
      authenticate_user!
      redirect_to root_path if user_signed_in? && !current_user.suspended?
    end
  end
  
end
