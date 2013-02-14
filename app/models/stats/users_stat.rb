module Stats
  class UsersStat < Base
    store_in collection: 'users_stats'

    # Legacy
    field :states_count, type: Hash

    field :be, type: Integer # beta
    field :fr, type: Integer # free
    field :pa, type: Integer # paying
    field :su, type: Integer # suspended
    field :ar, type: Integer # archived

    index d: 1

    def self.json_fields
      [:be, :fr, :pa, :su, :ar]
    end

    def self.create_stats
      self.create(stat_hash(Time.now.utc.midnight))
    end

    def self.stat_hash(day)
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
