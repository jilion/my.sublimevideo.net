module Zendesk
  class Client
    module Tags
      # @zendesk.tags
      # @zendesk.tags("cats", :tickets)
      def tags(*args)
        TagsCollection.new(self, *args)
      end
    end

    class TagsCollection < Collection
      def initialize(client, *args)
        super(client, :tag, *args)
      end
    end
  end
end
