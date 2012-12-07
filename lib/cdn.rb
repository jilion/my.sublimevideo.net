module CDN

  class << self

    # Works for file & directory
    def purge(path)
      @wrappers.each do |wrapper|
        wrapper.delay.purge(path)
      end
    end

    def wrappers=(wrappers)
      @wrappers = wrappers
    end

  end
end
