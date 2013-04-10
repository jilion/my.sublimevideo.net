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
  field :al, type: Hash     # alive (with page visits / video plays in the last 30 days): { "pv" => 12, "vv" => 6 }

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
        trend.update_attribute(:al, {
          pv: _number_of_sites_with_usage_in_the_last_30_days(trend_day, 'pv'),
          vv: _number_of_sites_with_usage_in_the_last_30_days(trend_day, 'vv')
        })
      end
      trend_day += 1.day
    end
  end

  def self.trend_hash(day)
    {
      d: day.to_time,
      fr: { free: Site.free.count },
      pa: { addons: Site.paying.count },
      su: Site.suspended.count,
      ar: Site.archived.count,
      al: {
        pv: _number_of_sites_with_usage_in_the_last_30_days(day, 'pv'),
        vv: _number_of_sites_with_usage_in_the_last_30_days(day, 'vv')
      }
    }
  end

  def self._number_of_sites_with_usage_in_the_last_30_days(day, metric)
    Site.where(token: Stat::Site::Day.between(d: (day - 30.days).midnight..day.yesterday.end_of_day)
    .or({ "#{metric}.m" => { "$gt" => 0 } }, { "#{metric}.e" => { "$gt" => 0 } }, { "#{metric}.em" => { "$gt" => 0 } }).distinct(:t)).count
  end

end
