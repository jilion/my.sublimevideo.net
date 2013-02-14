module Stats
  class TweetsStat < Base
    store_in collection: 'tweets_stats'

    field :k, type: Hash # keywords { "sublimevideo" => 2, "jw player" => 3 }

    index d: 1

    def self.json_fields
      [:k]
    end

    def self.determine_last_stat_day
      if TweetsStat.present?
        TweetsStat.order_by(d: 1).last.try(:d)
      else
        (Tweet.by_date('asc').first.tweeted_at).midnight - 1.day
      end
    end

    def self.stat_hash(day)
      tweets = Tweet.between(tweeted_at: day.beginning_of_day..day.end_of_day).all
      hash = {
        d: day.to_time,
        k: Hash.new(0)
      }

      tweets.each do |tweet|
        tweet.keywords.each { |keyword| hash[:k][keyword] += 1 }
      end

      hash
    end

  end
end
