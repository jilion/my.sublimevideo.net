module EdgeCast
  class Client
    module Media

      TYPES = [
        { :name => :wms, :keys => [:windows_media_streaming, :wms], :code => 1 },
        { :name => :fms, :keys => [:flash_media_streaming, :fms], :code => 2 },
        { :name => :hlo, :keys => [:http_large_object, :hlo], :code => 3 },
        { :name => :hso, :keys => [:http_small_object, :hso], :code => 8 },
        { :name => :adn, :keys => [:application_delivery_network, :adn], :code => 14 },
      ]

      def self.from_code(code)
        TYPES.find { |type| type[:code] == code }
      end

      def self.valid_type?(media_type, action = nil)
        case action
        when :load
          TYPES.select { |t| [:fms, :hlo, :hso, :adn].include?(t[:name]) }.any? { |t| t[:keys].include?(media_type) }
        when :purge
          TYPES.select { |t| [:wms, :fms, :hlo, :hso, :adn].include?(t[:name]) }.any? { |t| t[:keys].include?(media_type) }
        else
          !(from_key(media_type).nil? && from_code(media_type).nil?)
        end
      end

      def self.from_key(media_type)
        TYPES.find { |type| type[:keys].include?(media_type) }
      end

    end
  end
end
