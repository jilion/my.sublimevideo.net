module Service
  SupportRequest = Struct.new(:support_request) do

    class << self

      def build_support_request(params)
        new(::SupportRequest.new(params))
      end

      def create_zendesk_user(user)
        return if user.zendesk_id?

        zendesk_user = ZendeskWrapper.create_user(user)
        user.update_attribute(:zendesk_id, zendesk_user.id)
      end

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
end
