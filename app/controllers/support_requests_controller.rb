class SupportRequestsController < ApplicationController
  respond_to :html

  # POST /help
  def create
    @support_request = SupportRequest.new(params[:support_request].merge({ user_id: current_user.id }))

    respond_with(@support_request) do |format|
      if @support_request.delay_post
        format.html { redirect_to page_path('help'), notice: I18n.t('flash.support_requests.create.notice') }
      else
        format.html { render 'pages/help' }
      end
    end
  end

end