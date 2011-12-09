class UsersStat
  include Mongoid::Document
  include Mongoid::Timestamps

  # Legacy
  field :states_count, :type => Hash

  # New
  field :d,  type: DateTime  # Day
  field :fr, type: Integer # free
  field :pa, type: Integer # paying
  field :su, type: Integer # suspended
  field :ar, type: Integer # archived

  index :d
  index :created_at
  index [[:d, Mongo::ASCENDING], [:active, Mongo::ASCENDING]]
  index [[:d, Mongo::ASCENDING], [:passive, Mongo::ASCENDING]]

  # ==========
  # = Scopes =
  # ==========

  scope :between, lambda { |start_date, end_date| where(created_at: { "$gte" => start_date, "$lt" => end_date }) }

  # =================
  # = Class Methods =
  # =================

  # send time as id for backbonejs model
  def as_json(options = nil)
    json = super
    json['id'] = d.to_i
    json
  end

  class << self

    def json(from = nil, to = nil)
      json_stats = if from.present?
        between(from: from, to: to || Time.now.utc.midnight)
      else
        scoped
      end

      json_stats.to_json(only: [:fr, :pa, :su, :ar])
    end

    def delay_create_users_stats
      unless Delayed::Job.already_delayed?('%UsersStat%create_users_stats%')
        delay(:run_at => Time.now.utc.tomorrow.midnight).create_users_stats # every day
      end
    end

    def create_users_stats
      delay_create_users_stats
      self.create(
        d: Time.now.utc.midnight,
        # Legacy counters
        states_count: {
          active_and_billable_count:     User.paying.count,
          active_and_not_billable_count: User.free.count,
          suspended_count:               User.suspended.count,
          archived_count:                User.archived.count
        },
        # New counters
        fr: User.free.count,
        pa: User.paying.count,
        su: User.suspended.count,
        ar: User.archived.count
      )
    end

  end

end
