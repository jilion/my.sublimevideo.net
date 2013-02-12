class SupportRequestManager
  attr_reader :support_request

  def initialize(support_request)
    @support_request = support_request
  end

  def self.create_zendesk_user(user)
    return if user.zendesk_id?

    zendesk_user = ZendeskWrapper.create_user(user)
    user.update_attribute(:zendesk_id, zendesk_user.id)
  end

  def send
    if support_request.valid?
      ticket = ZendeskWrapper.create_ticket(support_request.to_params)
      set_user_zendesk_id(ticket) unless support_request.user.zendesk_id?
      true
    else
      false
    end
  end

  private

  def set_user_zendesk_id(ticket)
    support_request.user.update_attribute(:zendesk_id, ticket.requester_id)
    ZendeskWrapper.verify_user(ticket.requester_id)
  end
end
