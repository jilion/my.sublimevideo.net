class UserAgent
  module Browsers
    module Gecko

      # Galeon is based on Firefox and needs to be
			# tested before Firefox is tested
      GECKO_BROWSERS = [
        "Beonex",
        "BonEcho",
        "Camino",
        "Fennec",
        "Firebird",
        "Flock",
        "Galeon",
        "Iceweasel",
        "Minefield",
        %w[Navigator Netscape],
        "Phoenix",
        "Seamonkey",
        "Sunrise",
        "Thunderbird",
        "Firefox"
      ]

      def self.extend?(agent)
        agent.application && agent.application.product == "Mozilla"
      end

      def gecko?
        true
      end

      def browser
        bi = browser_info
        if bi
          bi.is_a?(Array) ? bi[1] : bi
        else
          super
        end
      end

      def version
        if browser == "Mozilla" && ua = detect_user_agent_by_comment(/^rv:([^\)]+).*/)
          ua.comment.detect { |comm| comm =~ /^rv:([^\)]+).*/ }
          $1
        else
          bi = browser_info
          if bi && v = send(bi.is_a?(Array) ? bi[0] : bi).version
            v.partition('/')[0] # Handle strange version specification like 'Sunrise/4.0.1/like'
          else
            super
          end
        end
      end

      def gecko_version
        # Normal way of retrieving Gecko version
        if ua = detect_user_agent_by_product(/gecko/i)
          ua.version unless ua.version == "0"

        # Handle this special case where Gecko is stored as a comment and not as a product:
        # - Mozilla/4.0 (compatible; Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.7.13) Gecko/20060414; Windows NT 5.1)
        elsif ua = detect_user_agent_by_comment(/gecko/i)
          ua.comment.detect { |c| c =~ %r{gecko/(.*)}i }
          $1
        else
          nil
        end
      end

      def os
        if ["Windows", "OS/2", "Nintendo DS"].include?(platform) && os_name = detect_name_and_version_in_comment(OperatingSystems::REGEXP_AND_NAMES)
          os_name

        elsif os_name = detect_name_and_version_in_product(OperatingSystems::REGEXP_AND_NAMES)
          os_name

        elsif regexp_and_os = OperatingSystems::REGEXP_AND_NAMES.detect { |regexp_and_os| application.comment && application.comment[application.comment[1] == 'U' ? 2 : 1] =~ regexp_and_os[0] }
          "#{regexp_and_os[1]}#{" #{$1}" unless !$1 || $1.strip.empty?}"
        elsif ua = detect { |ua| !ua.comment.nil? }
          os_name = ua.comment[ua.comment[1] == 'U' ? 2 : 1]
          os_name == 'Mobile' ? ua.comment[0] : os_name
        end
      end

      def language
        if ua = detect { |ua| !ua.comment.nil? }
          # In the following cases:
          # - Mozilla/5.0 (X11; U; SunOS sun4u; it-IT; ) Gecko/20080000 Firefox/3.0
          # - Mozilla/5.0 (compatible; N; Windows NT 5.1; en;) Gecko/20080325 Firefox/2.0.0.13
          # take the last comment.
          if ua.comment.size > (!detect_user_agent_by_comment(/compatible|sunos/i).nil? ? 4 : 3)

            # If Mozilla revision is just before last comment, return the last comment
            if ua.comment[-2] =~ /^rv:(.*)/
              ensure_existing_language(ua.comment.last) unless Platforms::REGEXP_AND_NAMES.detect { |regexp_and_platform| ua.comment.last =~ regexp_and_platform[0] }
            # otherwise return the one before the last
            else
              if !Platforms::REGEXP_AND_NAMES.detect { |regexp_and_platform| ua.comment[-2] =~ regexp_and_platform[0] }
                ensure_existing_language(ua.comment[-2])
              end
            end
          else
            # In this only case (comments with 3 parameters and the revision is the last comment), there is no language:
            # - Mozilla/5.0 (Macintosh; Intel Mac OS X 10.6; rv:2.0b8) Gecko/20100101 Firefox/4.0b8
            if !(ua.comment.last =~ /^rv:(.*)/ ||
                  Platforms::REGEXP_AND_NAMES.detect { |regexp_and_platform| ua.comment.last =~ regexp_and_platform[0] } ||
                  SECURITY.include?(ua.comment.last))
              ensure_existing_language(ua.comment.last)
            else
              super
            end
          end
        end
      end

      def security
        # Sometimes the first product has no comment, so take the first non-nil comment, e.g.:
        # - Mozilla/5.0 Galeon/1.0.3 (X11; Linux i686; U;) Gecko/0
        if ua = detect { |ua| !ua.comment.nil? }
          SECURITY[ua.comment[1]] || :strong
        else
          :strong
        end
      end

      def mobile?
        ua = detect { |ua| !ua.comment.nil? }
        ua.nil? ? false : ua.comment[1] == 'Mobile'
      end

      private

      def browser_info
        GECKO_BROWSERS.detect { |browser| detect_user_agent_by_product_or_comment(browser.is_a?(Array) ? browser[0] : browser) }
      end

    end
  end
end
