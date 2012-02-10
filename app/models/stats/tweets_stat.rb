module Stats
  class TweetsStat
    include Mongoid::Document
    include Mongoid::Timestamps

    store_in :tweets_stats

    field :d, type: DateTime # Day
    field :k, type: Hash     # keywords { "sublimevideo" => 2, "jw player" => 3 }

    index :d
    index :created_at

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
          between(from, to || Time.now.utc.midnight)
        else
          scoped
        end

        json_stats.order_by([:d, :asc]).to_json(only: [:k])
      end

      def create_stats
        last_stat_day = determine_last_stat_day

        while last_stat_day < 1.day.ago.midnight do
          last_stat_day += 1.day
          create_tweets_stat(last_stat_day)
        end
      end

      def determine_last_stat_day
        if TweetsStat.present?
          TweetsStat.order_by([:d, :asc]).last.try(:d)
        else
          (Tweet.order_by([:tweeted_at, :asc]).first.tweeted_at).midnight - 1.day
        end
      end

      def create_tweets_stat(day)
        tweets = Tweet.between(day.beginning_of_day, day.end_of_day).all

        self.create(tweets_hash(day, tweets))
      end

      def tweets_hash(day, tweets)
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
end
