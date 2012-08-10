module CDN

  class << self

    # Works for file & directory
    def purge(path)
      @wrappers.each { |w| w.purge(path) }
    end

    def wrappers=(wrappers)
      @wrappers = wrappers
    end

  end
end
