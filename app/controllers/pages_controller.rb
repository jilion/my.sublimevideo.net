class PagesController < ApplicationController
  skip_before_filter :authenticate_user!, if: :_terms_or_privacy_page?
  before_filter :_redirect_non_suspended_user!, if: :_suspended_page_and_non_suspended_user?
  before_filter :_prepare_support_request, if: :_help_page_user_signed_in?

  def show
    render params[:page]
  end

  private

  def _redirect_non_suspended_user!
    redirect_to root_path
  end

  def _prepare_support_request
    @support_request = SupportRequest.new({})
  end

  def _terms_or_privacy_page?
    params[:page].in?(%w[terms privacy])
  end

  def _suspended_page_and_non_suspended_user?
    params[:page] == 'suspended' && user_signed_in? && !current_user.suspended?
  end

  def _help_page_user_signed_in?
    params[:page] == 'help' && user_signed_in?
  end

end
