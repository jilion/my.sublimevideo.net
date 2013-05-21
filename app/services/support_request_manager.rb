# wrappers
require 'prowl_wrapper'
require 'zendesk_wrapper'

# services
require 'user_support_manager'

class SupportRequestManager
  attr_reader :support_request

  def self.create_zendesk_user(user)
    return if user.zendesk_id?

    zendesk_user = ZendeskWrapper.create_user(user)
    user.update_attribute(:zendesk_id, zendesk_user.id)
  end

  def initialize(support_request)
    @support_request = support_request
  end

  def deliver
    if support_request.valid?
      ticket = ZendeskWrapper.create_ticket(support_request.to_params)
      _set_user_zendesk_id(ticket)
      _notify_of_new_enterprise_support_ticket
      true
    else
      false
    end
  end

  private

  def _set_user_zendesk_id(ticket)
    unless support_request.user.zendesk_id?
      support_request.user.update_attribute(:zendesk_id, ticket.requester_id)
      ZendeskWrapper.verify_user(ticket.requester_id)
    end
  end

  def _notify_of_new_enterprise_support_ticket
    if UserSupportManager.new(support_request.user).enterprise_email_support?
      ProwlWrapper.notify('New enterprise-level ticket received!')
    end
  end
end
