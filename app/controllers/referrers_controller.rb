class ReferrersController < ApplicationController
  skip_before_filter :authenticate_user!

  # GET /r/:type/:token
  def redirect
    Referrer.create_or_update_from_type!(params[:token], request.referer, params[:type])
  rescue => ex
    Notify.send("Referrer (type: #{params[:type]}) creation problem from #{request.referer} for #{params[:token]}", :exception => ex)
  ensure
    redirect_to "http://sublimevideo.net"
  end

end
