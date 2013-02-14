module Stats
  class SitesStat < Base
    store_in collection: 'sites_stats'

    # Legacy
    field :states_count, type: Hash
    field :plans_count,  type: Hash

    field :fr, type: Hash     # free { "beta" => 2, "dev" => 3, "free" => 4 }
    field :sp, type: Integer  # sponsored
    field :tr, type: Integer  # trial
    field :pa, type: Hash     # paying: { "plus" => { "m" => 3, "y" => 4 }, "premium" => { "m" => 3, "y" => 4 } }
    field :su, type: Integer  # suspended
    field :ar, type: Integer  # archived

    index d: 1

    def self.json_fields
      [:fr, :sp, :tr, :pa, :su, :ar]
    end

    def self.create_stats
      self.create(stat_hash(Time.now.utc.midnight))
    end

    def self.stat_hash(day)
      {
        d: day.to_time,
        fr: { free: Site.free.count },
        pa: { addons: Site.paying.count },
        su: Site.suspended.count,
        ar: Site.archived.count
      }
    end

  end
end
