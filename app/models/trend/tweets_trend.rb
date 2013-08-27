class TweetsTrend
  include Mongoid::Document
  include Mongoid::Timestamps
  include Trend

  field :k, type: Hash # keywords { "sublimevideo" => 2, "jw player" => 3 }

  def self.json_fields
    [:k]
  end

  def self.determine_last_trend_day
    if self.present?
      self.order_by(d: 1).last.try(:d)
    else
      (Tweet.by_date('asc').first.tweeted_at).midnight - 1.day
    end
  end

  def self.trend_hash(day)
    tweets = Tweet.between(tweeted_at: day.beginning_of_day..day.end_of_day).all
    hash = {
      d: day.utc,
      k: Hash.new(0)
    }

    tweets.each do |tweet|
      tweet.keywords.each { |keyword| hash[:k][keyword] += 1 }
    end

    hash
  end

end
