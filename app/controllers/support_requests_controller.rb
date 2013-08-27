class SupportRequestsController < ApplicationController
  respond_to :html

  # POST /help
  def create
    @support_request = SupportRequest.new(_support_request_params)
    manager = SupportRequestManager.new(@support_request)

    respond_with(@support_request) do |format|
      if manager.send
        format.html { redirect_to page_path('help'), notice: I18n.t('flash.support_requests.create.notice') }
      else
        format.html { render 'pages/help' }
      end
    end
  end

  private

  def _support_request_params
    params.require(:support_request).permit(:site_token, :subject, :message, :test_page, :env, :uploads).merge(
      user_id: current_user.id)
  end

end
