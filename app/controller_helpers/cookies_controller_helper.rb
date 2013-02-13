module CookiesControllerHelper

  private

  def set_stage_cookie
    if user_signed_in? && @site
      cookies["stage-#{@site.token}"] ||= 'stable'
      if params[:new_stage]
        cookies["stage-#{@site.token}"] = params[:new_stage]
        redirect_to url_for and return
      end
    end
  end

  def set_logged_in_cookie
    if user_signed_in?
      cookies[:l] = {
        value: '1',
        expires: 2.weeks.from_now,
        domain: :all,
        secure: false
      }
    else
      cookies.delete :l, domain: :all
    end
  end

  def sign_out_and_delete_cookie
    sign_out(current_user)
    cookies.delete :l, domain: :all
  end

end

