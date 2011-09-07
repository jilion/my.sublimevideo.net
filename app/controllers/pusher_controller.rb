class PusherController < ApplicationController
  skip_before_filter :authenticate_user!
  protect_from_forgery :except => :auth

  def auth
    Rails.logger.debug params
    Rails.logger.debug params[:channel_name]
    Rails.logger.debug params["channel_name"]
    if current_user && current_user.accessible_channel?(params[:channel_name])
      response = Pusher[params[:channel_name]].authenticate(params[:socket_id])
      render :json => response
    else
      render :text => "Not authorized", :status => '403'
    end
  end
end
