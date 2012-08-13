module Zendesk
  class Client
    module Macros
      # @zendesk.macros
      # @zendesk.macros(123)
      def macros(*args)
        MacrosCollection.new(self, *args)
      end
    end

    class MacrosCollection < Collection
      def initialize(client, *args)
        super(client, :macro, *args)
      end
    end
  end
end
