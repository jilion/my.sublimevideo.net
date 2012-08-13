module Zendesk
  class Client
    module Tickets
      # @zendesk.tickets
      # @zendesk.tickets(123)
      def tickets(*args)
        TicketsCollection.new(self, *args)
      end
    end

    class TicketsCollection < Collection
      # TODO: document all the fields
      def initialize(client, *args)
        super(client, :ticket, *args)
      end

      def views
        @query[:path] = "/rules"
        self
      end

      # TODO: @zendesk.ticket(123).public_comment({ ... })
      # TODO: @zendesk.ticket(123).private_comment({ ... })
    end
  end
end
