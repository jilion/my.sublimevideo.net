class PagesController < ApplicationController
  skip_before_filter :authenticate_user!, :unless => proc { |c| params[:page] == 'suspended' }
  before_filter :redirect_non_suspended_user!, :if => proc { |c| params[:page] == 'suspended' && user_signed_in? && !current_user.suspended? }

  def show
    render params[:page]
  end

private

  def redirect_non_suspended_user!
    redirect_to root_path
  end

end
