class TweetsSyncerWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'low'

  # This method synchronize the locals favorites tweets with the favorites tweets of @sublimevideo on Twitter
  # It will never favorite/un-favorite tweets on Twitter
  # It simply favorite/un-favorite tweets locally regarding favorites tweets on Twitter
  #
  def perform
    _remote_favorite_tweets_not_favorited_locally.each do |fav_tweet_id_to_add|
      if tweet = _find_tweet(fav_tweet_id_to_add)
        tweet.update_attribute(:favorited, true)
      end
    end
  end

  private

  def _remote_favorite_tweets_not_favorited_locally
    twitter_favorites_ids = (TwitterWrapper.favorites('sublimevideo', include_entities: false) || []).map(&:id)
    local_favorites_ids   = Tweet.favorites.only(:tweet_id).pluck(:tweet_id)

    twitter_favorites_ids - local_favorites_ids
  end

  def _find_tweet(tweet_id)
    Tweet.where(tweet_id: tweet_id).first
  end

end
