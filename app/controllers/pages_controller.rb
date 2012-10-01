class PagesController < ApplicationController
  skip_before_filter :authenticate_user!, if: proc { |c| %w[terms privacy].include?(params[:page]) }
  before_filter :redirect_non_suspended_user!, if: proc { |c| params[:page] == 'suspended' && user_signed_in? && !current_user.suspended? }
  before_filter :prepare_support_request, if: proc { |c| params[:page] == 'help' && user_signed_in? }

  def show
    render params[:page]
  end

private

  def redirect_non_suspended_user!
    redirect_to root_path
  end

  def prepare_support_request
    @support_request = SupportRequest.new({})
  end

end
