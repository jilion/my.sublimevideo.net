# encoding: utf-8
class SitesTrend
  include Mongoid::Document
  include Mongoid::Timestamps
  include Trend

  # Legacy
  field :states_count, type: Hash
  field :plans_count,  type: Hash

  field :fr, type: Hash     # free { "beta" => 2, "dev" => 3, "free" => 4 }
  field :sp, type: Integer  # sponsored
  field :tr, type: Integer  # trial
  field :pa, type: Hash     # paying: { "plus" => { "m" => 3, "y" => 4 }, "premium" => { "m" => 3, "y" => 4 } }
  field :su, type: Integer  # suspended
  field :ar, type: Integer  # archived

  def self.json_fields
    [:fr, :sp, :tr, :pa, :su, :ar]
  end

  def self.create_trends
    self.create(trend_hash(Time.now.utc.midnight))
  end

  def self.trend_hash(day)
    {
      d: day.to_time,
      fr: { free: Site.free.count },
      pa: { addons: Site.paying.count },
      su: Site.suspended.count,
      ar: Site.archived.count
    }
  end

end
