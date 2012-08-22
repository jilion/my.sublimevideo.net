module SupportRequestsHelper

  def support_presence
    if (9...18).include?(Time.now.utc.in_time_zone('Bern').hour)
      "we are #{content_tag(:strong, 'currently present', style: 'color:green')}"
    else
      "we are #{content_tag(:strong, 'not currently present', style: 'color:red')}"
    end
  end

  def support_request_site_token_options
    options_for_select([[t("support_request.site_token.choose-site_token"), ''], ["-"*16, '-']] + current_user.sites.active.map { |s| [s.hostname_or_token, s.token] }, selected: params[:support_request] ? params[:support_request][:site_token] : nil, disabled: ['-'])
  end

end
