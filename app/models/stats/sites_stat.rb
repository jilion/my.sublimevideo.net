module Stats
  class SitesStat
    include Mongoid::Document
    include Mongoid::Timestamps

    store_in collection: 'sites_stats'

    # Legacy
    field :states_count, type: Hash
    field :plans_count,  type: Hash

    field :d,  type: DateTime # Day
    field :fr, type: Hash     # free { "beta" => 2, "dev" => 3, "free" => 4 }
    field :sp, type: Integer  # sponsored
    field :tr, type: Integer  # trial
    field :pa, type: Hash     # paying: { "plus" => { "m" => 3, "y" => 4 }, "premium" => { "m" => 3, "y" => 4 } }
    field :su, type: Integer  # suspended
    field :ar, type: Integer  # archived

    index d: 1

    # ==========
    # = Scopes =
    # ==========

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

        json_stats.order_by(d: 1).to_json(only: [:fr, :sp, :tr, :pa, :su, :ar])
      end

      def create_stats
        self.create(sites_hash(Time.now.utc.midnight))
      end

      def sites_hash(day)
        hash = {
          d: day.to_time,
          fr: { free: Site.free.count },
          pa: { addons: Site.paying.count },
          su: Site.suspended.count,
          ar: Site.archived.count
        }

        hash
      end

    end

  end
end
