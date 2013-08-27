class TailorMadePlayerRequestsTrend
  include Mongoid::Document
  include Mongoid::Timestamps
  include Trend

  field :n, type: Hash # new { "agency" => 1, "standalone" => 2, "platform" => 3, "other" => 4 }

  def self.json_fields
    [:n]
  end

  def self.determine_last_trend_day
    if self.present?
      self.order_by(d: 1).last.try(:d)
    else
      (TailorMadePlayerRequest.all(by_date: 'asc').first.created_at).midnight - 1.day
    end
  end

  def self.update_trends(start_day = nil)
    scope = if start_day
      where(d: { :$gte => start_day.midnight })
    else
      all
    end

    scope.each do |trend|
      trend.update(trend_hash(trend.d))
    end
  end

  def self.trend_hash(day)
    hash = {
      d: day.utc,
      n: Hash.new(0)
    }

    TailorMadePlayerRequest.topics.each do |topic|
      hash[:n][topic] = TailorMadePlayerRequest.count(with_topic: topic, created_before: day.end_of_day)
    end

    hash
  end

end
