module OneTime
  module Stats
    module SitesStat

      class << self

        def reduce_trial_hash
          summary = ''
          ::Stats::SitesStat.all.each do |stats|
            if stats[:tr].respond_to?(:inject)
              reduced_value = reduce_hash(stats[:tr])
              summary += "#{stats[:tr].inspect} reduced into #{reduced_value}"
              stats.update_attribute(:tr, reduced_value)
            end
          end
          summary
        end

        private

        def reduce_hash(hash_or_fixnum)
          if hash_or_fixnum.respond_to?(:inject)
            hash_or_fixnum.inject(0) do |memo, h|
              memo += reduce_hash(h[1])
              memo
            end
          else
            hash_or_fixnum
          end
        end

      end

    end
  end
end
