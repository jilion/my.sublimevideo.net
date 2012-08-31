class UserAgent
  module Browsers
    module InternetExplorer

      def self.extend?(agent)
        !agent.detect_user_agent_by_comment(/MSIE/i).nil?
      end

      def browser
        "Internet Explorer"
      end

      def version
        # Take all the potential "MSIE X.X" strings
        msie_versions = collect_user_agent_by_comment(/MSIE\s/i)
        msie_versions.compact.collect { |v| v.sub(/MSIE\s/i, "") }.max # Take the biggest version
      end

      def compatible?
        !detect_user_agent_by_comment(/compatible/i).nil?
      end

      # Before version 4.0, Chrome Frame declared itself (unversioned) in a comment;
      # as of 4.0 it declares itself as a separate product with a version.
      def chromeframe
        detect_user_agent_by_product_or_comment("chromeframe")
      end

      def chromeframe_version
        if ua = detect_user_agent_by_product(/chromeframe/i)
          ua.version
        elsif ua = detect_user_agent_by_comment(/chromeframe/i)
          version = ua.comment.detect { |c| c =~ %r{chromeframe/}i }
          version.sub(%r{chromeframe/}i, "") unless version.nil?
        else
          nil
        end
      end

      def mobile?
        ![/Windows CE/, /Windows Phone OS/].detect { |regex| regex =~ os }.nil? || !detect_user_agent_by_comment(/IEMobile/).nil?
      end

    end
  end
end
