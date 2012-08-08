module Zendesk
  class Client
    module TicketFields
      # @zendesk.ticket_fields
      # @zendesk.ticket_fields(123)
      def ticket_fields(*args)
        TicketFieldsCollection.new(self, *args)
      end

      class TicketFieldsCollection < Collection
        def initialize(client, *args)
          super(client, :ticket_field, *args)
        end
      end
    end
  end
end
