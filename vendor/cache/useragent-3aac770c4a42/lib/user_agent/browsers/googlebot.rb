class UserAgent
  module Browsers
    module Googlebot
      def self.extend?(agent)
        agent.detect_user_agent_by_product_or_comment('Googlebot')
      end

      def browser
        "Googlebot"
      end

      def version
        if ua = detect_user_agent_by_comment(%r{Googlebot/})
          ua.comment.detect { |comm| comm =~ %r{Googlebot/(\S+)} }
          $1
        else
         application.version
       end
      end

      def compatibility
        application.comment ? application.comment[0] : nil
      end

      def compatible?
        compatibility == "compatible"
      end

      def crawler?
        true
      end
    end
  end
end
