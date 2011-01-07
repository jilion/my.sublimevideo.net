module TicketsHelper

  def ticket_type_options
    options_for_select([[t("ticket.type.choose-type"), 'choose-type'], ["-"*16, '-']] + Ticket::TYPES.map { |t| [t("ticket.type.#{t}"), t] }, :selected => params[:ticket] ? params[:ticket][:type] : nil, :disabled => ['-'])
  end

end
