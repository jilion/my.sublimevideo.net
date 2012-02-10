class Www::ReferrersController < MyController
  skip_before_filter :authenticate_user!

  # GET /r/:type/:token
  def redirect
    Referrer.create_or_update_from_type(params[:token], request.referer, params[:type])
    set_referrer_token_in_cookie
  rescue => ex
    Notify.send("Referrer (type: #{params[:type]}) creation problem from #{request.referer} for #{params[:token]}", exception: ex)
  ensure
    redirect_to root_url(host: request.domain)
  end

private

  def set_referrer_token_in_cookie
    cookies[:r] = {
      value: params[:token],
      expires: 1.year.from_now,
      domain: :all
    }
  end

end
