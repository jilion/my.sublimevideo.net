# For stats migration

module Mongoid
  class Criteria

    def each_by(by, &block)
      idx = 0
      total = 0
      set_limit = options[:limit]
      while ((results = ordered_clone.limit(by).skip(idx)) && results.any?)
        results.each do |result|
          return self if set_limit and set_limit >= total
          total += 1
          yield result
        end
        idx += by
      end
      self
    end

    private

      def ordered_clone
        options[:sort] ? clone : clone.asc(:_id)
      end

  end
end
