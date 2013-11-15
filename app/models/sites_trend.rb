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
  field :al, type: Hash     # alive (with more than threshold starts in the last 30 days): { "st1" => 12, "st2" => 12, "st100" => 12 }

  def self.json_fields
    [:fr, :sp, :tr, :pa, :su, :ar, :al]
  end

  def self.create_trends
    self.create(trend_hash(Time.now.utc.midnight))
  end

  def self.update_alive_sites_trends
    trend_day = self.order_by(d: 1).first.try(:d)

    while trend_day <= Time.now.utc.midnight do
      if trend = self.where(d: trend_day).first
        trend.update_attribute(:al, alive_sites_trend_hash(trend_day))
      end
      trend_day += 1.day
    end
  end

  def self.trend_hash(day)
    {
      d:  day.utc,
      fr: { free: Site.free.count },
      pa: { addons: Site.paying.count },
      su: Site.suspended.count,
      ar: Site.archived.count,
      al: alive_sites_trend_hash(day)
    }
  end

  def self.alive_sites_trend_hash(day)
    [1, 2, 100].inject({}) do |hash, threshold|
      hash["st#{threshold}"] = SiteAdminStat.last_30_days_sites_with_starts(day.to_date, threshold: threshold)
      hash
    end
  end

end
