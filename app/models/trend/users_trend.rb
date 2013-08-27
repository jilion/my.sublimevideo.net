class UsersTrend
  include Mongoid::Document
  include Mongoid::Timestamps
  include Trend

  # Legacy
  field :states_count, type: Hash

  field :be, type: Integer # beta
  field :fr, type: Integer # free
  field :pa, type: Integer # paying
  field :su, type: Integer # suspended
  field :ar, type: Integer # archived

  def self.json_fields
    [:be, :fr, :pa, :su, :ar]
  end

  def self.create_trends
    self.create(trend_hash(Time.now.utc.midnight))
  end

  def self.trend_hash(day)
    {
      d:  day.utc,
      be: 0,
      fr: User.free.count,
      pa: User.paying.count,
      su: User.suspended.count,
      ar: User.archived.count
    }
  end

end
