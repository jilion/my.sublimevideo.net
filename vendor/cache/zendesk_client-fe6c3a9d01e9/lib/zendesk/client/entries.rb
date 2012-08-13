module Zendesk
  class Client
    module Entries
      # @zendesk.entries
      # @zendesk.entries(123)
      def entries(*args)
        EntriesCollection.new(self, *args)
      end
    end

    class EntriesCollection < Collection
      def initialize(client, *args)
        super(client, :entry, *args)
      end
    end
  end
end
