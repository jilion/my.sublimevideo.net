module Stats
  class TailorMadePlayerRequestsStat
    include Mongoid::Document
    include Mongoid::Timestamps

    store_in collection: 'tailor_made_player_requests_stats'

    field :d, type: DateTime # Day
    field :n, type: Hash     # new { "agency" => 1, "standalone" => 2, "platform" => 3, "other" => 4 }

    index d: 1
    index created_at: 1

    # send time as id for backbonejs model
    def as_json(options = nil)
      json = super
      json['id'] = d.to_i
      json
    end

    # =================
    # = Class Methods =
    # =================

    class << self

      def json(from = nil, to = nil)
        json_stats = if from.present?
          between(d: from..(to || Time.now.utc.midnight))
        else
          scoped
        end

        json_stats.order_by(d: 1).to_json(only: [:n])
      end

      def create_stats
        last_stat_day = determine_last_stat_day

        while last_stat_day < 1.day.ago.midnight do
          last_stat_day += 1.day
          create_tailor_made_player_requests_stat(last_stat_day)
        end
      end

      def update_stats(start_day = nil)
        scope = if start_day
          where(d: { :$gte => start_day.midnight })
        else
          all
        end

        scope.each do |stat|
          stat.update_attributes(tailor_made_player_requests_hash(stat.d))
        end
      end

      def determine_last_stat_day
        if TailorMadePlayerRequestsStat.present?
          TailorMadePlayerRequestsStat.order_by(d: 1).last.try(:d)
        else
          (TailorMadePlayerRequest.by_date('asc').first.created_at).midnight - 1.day
        end
      end

      def create_tailor_made_player_requests_stat(day)
        self.create(tailor_made_player_requests_hash(day))
      end

      def tailor_made_player_requests_hash(day)
        tailor_made_player_requests = TailorMadePlayerRequest.where { created_at <= day.end_of_day }.all
        hash = {
          d: day.to_time,
          n: Hash.new(0)
        }

        tailor_made_player_requests.each do |tailor_made_player_request|
          hash[:n][tailor_made_player_request.topic] += 1
        end

        hash
      end

    end

  end
end
