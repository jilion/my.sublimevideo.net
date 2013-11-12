class SiteAdminStatsTrend
  include Mongoid::Document
  include Mongoid::Timestamps
  include Trend

  field :al, as: :app_loads, type: Hash, default: {} # { m(main): 1, e(extra): 3, s(staging): 5, d(dev): 11, i(invalid): 1 }
  field :lo, as: :loads, type: Hash, default: {} # { w(website): 3, e(external): 9 }, even without video_uid
  field :st, as: :starts, type: Hash, default: {} # { w(website): 3, e(external): 9 }, even without video_uid

  def self.json_fields
    [:al, :lo, :st]
  end

  def self.determine_last_trend_day
    if self.present?
      self.order_by(d: 1).last.try(:d)
    else
      Time.utc(2011, 11, 29)
    end
  end

  def self.trend_hash(day)
    global_stats = SiteAdminStat.global_day_stat(day.to_date)
    global_stats.merge(d:  day.utc)
  end

end
