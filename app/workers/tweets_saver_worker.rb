class TweetsSaverWorker
  include Sidekiq::Worker
  sidekiq_options queue: 'low'

  def perform(keyword)
    max_id = nil
    while search = _remote_search(keyword, max_id) and !search.results.empty?
      search.results.each do |tweet|
        if tweet = _find_tweet(tweet.id)
          tweet.add_to_set(keywords: keyword) unless tweet.keywords.include?(keyword)
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
