module CDN
  WRAPPERS = [EdgeCastWrapper, VoxcastWrapper]

  class << self
    # Works for file & directory
    def purge(path)
      wrappers.each do |wrapper|
        wrapper.delay.purge(path)
      end
    end

    def wrappers
      WRAPPERS
    end
  end
end
