module Zendesk
  class Client
    module Forums
      # @zendesk.forums
      # @zendesk.forums(123)
      def forums(*args)
        ForumsCollection.new(self, *args)
      end
    end

    class ForumsCollection < Collection

      def initialize(client, *args)
        super(client, :forum, *args)
      end

      # @zendesk.forums(123).entries
      def entries
        @query[:path] += "/entries"
        self
      end
    end
  end
end
