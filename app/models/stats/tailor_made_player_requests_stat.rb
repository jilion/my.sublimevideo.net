module Stats
  class TailorMadePlayerRequestsStat < Base
    store_in collection: 'tailor_made_player_requests_stats'

    field :n, type: Hash # new { "agency" => 1, "standalone" => 2, "platform" => 3, "other" => 4 }

    index d: 1

    def self.json_fields
      [:n]
    end

    def self.determine_last_stat_day
      if TailorMadePlayerRequestsStat.present?
        TailorMadePlayerRequestsStat.order_by(d: 1).last.try(:d)
      else
        (TailorMadePlayerRequest.all(by_date: 'asc').first.created_at).midnight - 1.day
      end
    end

    def self.update_stats(start_day = nil)
      scope = if start_day
        where(d: { :$gte => start_day.midnight })
      else
        all
      end

      scope.each do |stat|
        stat.update_attributes(stat_hash(stat.d))
      end
    end

    def self.stat_hash(day)
      hash = {
        d: day.to_time,
        n: Hash.new(0)
      }

      TailorMadePlayerRequest.topics.each do |topic|
        hash[:n][topic] = TailorMadePlayerRequest.count(with_topic: topic, created_before: day.end_of_day)
      end

      hash
    end

  end
end
