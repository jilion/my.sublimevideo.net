module SupportRequestsHelper

  def support_available?
    (9...18).include?(Time.now.utc.in_time_zone('Bern').hour)
  end

  def support_availability_sentence
    if support_available?
      "The support team is #{content_tag(:strong, 'currently available')}."
    else
      "The support team is #{content_tag(:strong, 'not currently available')}."
    end
  end

  def support_availability_class
    support_available? ? "available" : "not_available"
  end

  def support_request_site_token_options
    options_for_select([[t("support_request.site_token.choose-site_token"), ''], ['', '', { disabled: true }]] + current_user.sites.active.map { |s| [hostname_or_token(s), s.token] }, selected: params[:support_request] ? params[:support_request][:site_token] : nil, disabled: ['-'])
  end

  def support_request_stage_options
    options_for_select([[t("support_request.stage.choose-stage"), ''], ['', '', { disabled: true }], ['Stable', 'stable'], ['Beta', 'beta']])
  end

end
