class PusherController < ActionController::Base

  # POST /pusher/auth
  def auth
    if PusherChannel.new(params[:channel_name]).accessible?(current_user)
      authenticated_response = PusherWrapper.authenticated_response(
        params[:channel_name],
        params[:socket_id])
      render json: authenticated_response
    else
      render text: 'Forbidden', status: '403'
    end
  end

  # POST /pusher/webhook
  def webhook
    webhook = Pusher::WebHook.new(request)
    if webhook.valid?
      PusherWrapper.handle_webhook(webhook)
      render text: 'ok'
    else
      render text: 'invalid', status: 401
    end
  end

end
