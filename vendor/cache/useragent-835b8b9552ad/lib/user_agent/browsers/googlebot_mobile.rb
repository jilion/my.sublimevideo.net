class UserAgent
  module Browsers
    module GooglebotMobile
      def self.extend?(agent)
        agent.detect_user_agent_by_product_or_comment('Googlebot-Mobile')
      end

      def browser
        "Googlebot-Mobile"
      end

      def version
        ua = detect_user_agent_by_comment(/compatible/i)
        if ua && ua.comment && ua.comment[1]
          ua.comment[1].sub('Googlebot-Mobile/', '')
        else
          application.version ? application.version.sub(';', '') : nil
        end
      end

      def compatibility
        ua = detect_user_agent_by_comment(/compatible/i)
        (ua && ua.comment) ? ua.comment[0] : nil
      end

      def compatible?
        compatibility == "compatible"
      end

      def crawler?
        true
      end

      def mobile?
        true
      end
    end
  end
end
