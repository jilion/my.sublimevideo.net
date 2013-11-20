class TweetsSaverWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'my-low'

  def perform(keyword)
    max_id = nil
    while search = _remote_search(keyword, max_id) and !search.to_a.empty?
      search.to_a.each do |tweet|
        if local_tweet = _find_tweet(tweet.id)
          local_tweet.add_to_set(keywords: keyword) unless local_tweet.keywords.include?(keyword)
        else
          Tweet.create_from_twitter_tweet!(tweet)
        end
      end
      max_id = search.max_id
    end
  end

  private

  def _find_tweet(tweet_id)
    Tweet.where(tweet_id: tweet_id).first
  end

  def _remote_search(keyword, max_id)
    TwitterWrapper.search("\"#{keyword}\"", result_type: 'recent', count: 100, since_id: max_id)
  end

end
