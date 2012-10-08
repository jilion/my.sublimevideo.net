require_dependency 'service/support_request'

class SupportRequestsController < ApplicationController
  respond_to :html

  # POST /help
  def create
    manager          = Service::SupportRequest.build_support_request(params[:support_request].merge(user_id: current_user.id))
    @support_request = manager.support_request

    respond_with(@support_request) do |format|
      if manager.send
        format.html { redirect_to page_path('help'), notice: I18n.t('flash.support_requests.create.notice') }
      else
        format.html { render 'pages/help' }
      end
    end
  end

end
