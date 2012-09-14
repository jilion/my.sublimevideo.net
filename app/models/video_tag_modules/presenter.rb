module VideoTagModules
  module Presenter
    extend ActiveSupport::Concern

    def poster(size = :large)
      p
    end

    # HD in seconds
    def sources
      cs.map { |crc32| s[crc32] }.compact
    end

  end
end
