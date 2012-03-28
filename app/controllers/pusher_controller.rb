class PusherController < ApplicationController
  skip_before_filter :authenticate_user!
  protect_from_forgery except: :auth

  def auth
    if User.accessible_channel?(params[:channel_name], current_user)
      response = Pusher[params[:channel_name]].authenticate(params[:socket_id])
      render json: response
    else
      render text: "Not authorized", status: '403'
    end
  end
end
