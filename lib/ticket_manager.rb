require 'zendesk_wrapper'

class TicketManager

  class << self

    def create(support_request)
      ticket = ZendeskWrapper.create_ticket(support_request.to_params)
      set_user_zendesk_id(ticket, support_request.user) unless support_request.user.zendesk_id?
    end

    def set_user_zendesk_id(ticket, user)
      user.update_attribute(:zendesk_id, ticket.requester_id)
      ticket.verify_user
    end

  end

end
