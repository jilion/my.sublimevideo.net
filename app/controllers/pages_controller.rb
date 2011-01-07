class PagesController < ApplicationController
  skip_before_filter :authenticate_user!, :unless => proc { |c| params[:page] == 'suspended' }
  before_filter :redirect_suspended_user!

  def show
    render params[:page]
  end

protected

  def redirect_suspended_user!
    redirect_to root_path if params[:page] == 'suspended' && user_signed_in? && !current_user.suspended?
  end

end
