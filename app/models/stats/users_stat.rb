module Stats
  class UsersStat
    include Mongoid::Document
    include Mongoid::Timestamps

    store_in collection: 'users_stats'

    # Legacy
    field :states_count, type: Hash

    field :d,  type: DateTime # Day
    field :be, type: Integer # beta
    field :fr, type: Integer # free
    field :pa, type: Integer # paying
    field :su, type: Integer # suspended
    field :ar, type: Integer # archived

    index d: 1

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

        json_stats.order_by(d: 1).to_json(only: [:be, :fr, :pa, :su, :ar])
      end

      def create_stats
        self.create(users_hash(Time.now.utc.midnight))
      end

      def users_hash(day)
        {
          d: day.to_time,
          be: 0,
          fr: User.free.count,
          pa: User.paying.count,
          su: User.suspended.count,
          ar: User.archived.count
        }
      end

    end

  end
end
