module SupportRequestsHelper

  def support_available?
    (9...18).include?(Time.now.utc.in_time_zone('Bern').hour)
  end

  def support_availability_sentence
    text = ['The support team is']
    text << (support_available? ? content_tag(:strong, 'currently available') : content_tag(:strong, 'not currently available'))

    (text.join(' ') + '.').html_safe
  end

  def support_availability_class
    support_available? ? 'available' : 'not_available'
  end

  def support_request_site_token_options
    options_for_select([[t('support_request.site_token.choose-site_token'), ''], ['', '', { disabled: true }]] + current_user.sites.active.map { |s| [hostname_or_token(s), s.token] }, selected: params[:support_request] ? params[:support_request][:site_token] : nil, disabled: ['-'])
  end

  def email_support_response_time
    case _user_support_manager.guaranteed_response_time
    when 5.days
      '5 business days'
    when 1.day
      'business day'
    when 1.hour
      'hour (during business hours)'
    end
  end

  def email_support?
    _user_support_manager.email_support?
  end

  def vip_email_support?
    _user_support_manager.vip_email_support?
  end

  def enterprise_email_support?
    _user_support_manager.enterprise_email_support?
  end

  def _user_support_manager
    @user_support_manager ||= UserSupportManager.new(@current_user)
  end

end
