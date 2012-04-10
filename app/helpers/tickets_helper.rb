module TicketsHelper

  def ticket_type_options
    options_for_select([[t("ticket.type.choose-type"), 'choose-type'], ["-"*16, '-']] + Ticket::EMAIL_SUPPORT_ALLOWED_TYPES.map { |t| [t("ticket.type.#{t}"), t] }, selected: params[:ticket] ? params[:ticket][:type] : nil, disabled: ['-'])
  end

  def ticket_site_token_options
    options_for_select([[t("ticket.site_token.choose-site_token"), ''], ["-"*16, '-']] + current_user.sites.active.map { |s| [s.hostname_or_token, s.token] }, selected: params[:ticket] ? params[:ticket][:site_token] : nil, disabled: ['-'])
  end

end
