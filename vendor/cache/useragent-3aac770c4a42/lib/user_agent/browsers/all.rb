class UserAgent
  module Browsers
    module All
      include Comparable

      def <=>(other)
        if respond_to?(:browser) && other.respond_to?(:browser) && browser == other.browser
          Gem::Version.new(version) <=> Gem::Version.new(other.version)
        else
          false
        end
      end

      def eql?(other)
        self == other
      end

      def to_str
        join(" ")
      end
      alias :to_s :to_str

      # By default, all parsed UserAgent strings represent browsers
      def type
        :browser
      end

      def gecko?
        false
      end

      def webkit?
        false
      end
      
      def crawler?
        false
      end

      def application
        first
      end

      def browser
        application ? application.product : nil
      end

      def version
        application ? application.version : nil
      end

      def platform
        detect_name_from(Platforms::REGEXP_AND_NAMES)
      end

      def os
        name_only = (platform == "BlackBerry") # Special case for BlackBerry
        detect_name_and_version_from(OperatingSystems::REGEXP_AND_NAMES, :name_only => name_only)
      end

      # Linux specific
      def linux_distribution
        if platform == "Linux"
          if distro = detect_name_and_version_from(LinuxDistributions::REGEXP_AND_NAMES)
            distro
          else
            # Special case for Red Hat
            if detect_user_agent_by_product(/red/i) && red_hat = detect_user_agent_by_product(/hat/i)
              "Red Hat#{" #{red_hat.version}" if red_hat.version}"
            else
              nil
            end
          end
        end
      end

      # General information
      def language
        ua = nil
        if regexp_and_name = Languages::REGEXP_AND_NAMES.detect { |regexp_and_name| ua = detect_user_agent_by_comment(/^#{regexp_and_name[0]}(([-_][a-zA-Z]{2})|[-_])?$/) }
          ua.comment.detect { |comm| comm =~ /^#{regexp_and_name[0]}(?:[-_]([a-zA-Z]{2})|[-_])?$/ }
        "#{regexp_and_name[0].source}#{"-#{$1.upcase}" if $1}"

        # Special case for 'Mozilla/4.79 [en] (compatible; MSIE 7.0; Windows NT 5.0)'
        elsif regexp_and_name = Languages::REGEXP_AND_NAMES.detect { |regexp_and_name| ua = detect_user_agent_by_product(/^\[#{regexp_and_name[0]}(([-_][a-zA-Z]{2})|[-_])?\]$/) }
          ua.comment.detect { |comm| comm =~ /^\[#{regexp_and_name[0]}(?:[-_]([a-zA-Z]{2})|[-_])?\]$/ }
          "#{regexp_and_name[0].source}#{"-#{$1.upcase}" if $1}"

        else
          nil
        end
      end

      # General information
      def security
        if security = Browsers::SECURITY.detect { |security| detect_user_agent_by_comment(security[0]) }
          security[1]
        end
      end

      # By default, all parsed UserAgent strings represent desktop browsers
      def mobile?
        false
      end

      # Utilities
      def detect_user_agent_by_product(product)
        detect do |useragent|
          product.is_a?(Regexp) ? (useragent.product.to_s =~ product) : (useragent.product.to_s.downcase == product.to_s.downcase)
        end
      end

      def detect_user_agent_by_comment(comment)
        detect do |useragent|
          useragent.comment && useragent.comment.detect do |comm|
            comment.is_a?(Regexp) ? (comm.to_s =~ comment) : (comm.to_s.downcase == comment.to_s.downcase)
          end
        end
      end

      def detect_user_agent_by_product_or_comment(symbol)
        detect_user_agent_by_product(/#{symbol}/i) || detect_user_agent_by_comment(/#{symbol}/i)
      end

      def collect_user_agent_by_comment(comment)
        collect { |ua| ua.comment.detect { |c| c =~ comment } unless ua.comment.nil? }
      end

      def method_missing(method, *args, &block)
        detect_user_agent_by_product_or_comment(method) || super
      end

    private

      def detect_name_and_version_from(regexp_and_names, options={})
        detect_name_and_version_in_comment(regexp_and_names, options) ||
          detect_name_and_version_in_product(regexp_and_names, options)
      end

      def detect_name_from(regexp_and_names)
        detect_name_and_version_in_product(regexp_and_names, :name_only => true) ||
          detect_name_and_version_in_comment(regexp_and_names, :name_only => true)
      end

      def detect_version_from(regexp_and_names)
        detect_name_and_version_in_comment(regexp_and_names, :version_only => true) ||
          detect_name_and_version_in_product(regexp_and_names, :version_only => true)
      end

      def detect_name_and_version_in_comment(regexp_and_names, options={ :name_only => false, :version_only => false })
        ua = nil
        if regexp_and_name = regexp_and_names.detect { |regexp_and_name| ua = detect_user_agent_by_comment(regexp_and_name[0]) }
          if options[:name_only]
            regexp_and_name[1]
          else
            ua.comment.detect { |comment| comment =~ regexp_and_name[0] }

            if options[:version_only]
              $1
            else
              "#{regexp_and_name[1]}#{" #{$1}" if !$1.nil? && !$1.strip.empty?}"
            end
          end
        else
          nil
        end
      end

      def detect_name_and_version_in_product(regexp_and_names, options={ :name_only => false, :version_only => false })
        ua = nil
        if regexp_and_name = regexp_and_names.detect { |regexp_and_name| ua = detect_user_agent_by_product(regexp_and_name[0]) }
          if options[:name_only]
            regexp_and_name[1]
          else

            if options[:version_only]
              ua.version
            else
              "#{regexp_and_name[1]}#{" #{ua.version}" if ua.version}"
            end
          end
        else
          nil
        end
      end

      # Ensure given text is a valid language (check against ISO-639-2 official languages list)
      # More info in UserAgent::Languages
      def ensure_existing_language(text)
        Languages::REGEXP_AND_NAMES.detect { |regexp_and_name| text =~ /^#{regexp_and_name[0]}/ } ? text : nil
      end

    end
  end
end
