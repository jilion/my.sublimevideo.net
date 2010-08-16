module TicketsHelper
  
  def ticket_type_options
    options_for_select([[t("ticket.type.choose_type"), 'choose_type'], ["-"*16, '-']] + Ticket.ordered_types.map(&:first).map(&:first).map { |k| [t("ticket.type.#{k.to_s}"), k.to_s] })
  end
  
end