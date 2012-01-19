module Stats
  class UsersStat
    include Mongoid::Document
    include Mongoid::Timestamps

    store_in :users_stats

    # Legacy
    field :states_count, type: Hash

    field :d,  type: DateTime # Day
    field :be, type: Integer # beta
    field :fr, type: Integer # free
    field :pa, type: Integer # paying
    field :su, type: Integer # suspended
    field :ar, type: Integer # archived

    index :d

    # ==========
    # = Scopes =
    # ==========

    scope :between, lambda { |start_date, end_date| where(d: { "$gte" => start_date, "$lt" => end_date }) }

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
          between(from: from, to: to || Time.now.utc.midnight)
        else
          scoped
        end

        json_stats.order_by([:d, :asc]).to_json(only: [:be, :fr, :pa, :su, :ar])
      end

      def delay_create_users_stats
        unless Delayed::Job.already_delayed?('%Stats::UsersStat%create_users_stats%')
          delay(:run_at => Time.now.utc.tomorrow.midnight).create_users_stats # every day
        end
      end

      def create_users_stats
        delay_create_users_stats
        self.create(
          d: Time.now.utc.midnight,
          be: 0,
          fr: User.free.count,
          pa: User.paying.count,
          su: User.suspended.count,
          ar: User.archived.count
        )
      end

    end

  end
end
