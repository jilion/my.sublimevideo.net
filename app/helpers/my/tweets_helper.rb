module My::TweetsHelper

  # Fetch +count+ tweets randomly from the 20 cached last favorite tweets, sorted by date desc
  def random_favorite_tweets(count = 3)
    cached_last_favorite_tweets(20).sample(count).sort { |a, b| b.created_at <=> a.created_at }
  end

  # Fetch +count+ last favorite tweets and cache the array for 1 hour
  def cached_last_favorite_tweets(count)
    favorite_tweets_options = { user_doublon: false, count: count, random: true, since_date: Time.utc(2011,3,29), include_entities: true }
    if from_cache = Rails.cache.fetch("what_people_say_#{count}")
      from_cache
    else
      favorites_tweets = Tweet.pretty_remote_favorites(favorite_tweets_options)
      Rails.cache.write("what_people_say_#{count}", favorites_tweets, expires_in: 1.hour) if favorites_tweets.present?
      favorites_tweets
    end
  end

  def clean_tweet_text(tweet, *args)
    tweet_text     = tweet.text
    tweet_entities = tweet.attrs['entities'].to_options
    options        = args.extract_options!
    indices_for_stripping = []

    indices_for_stripping << tweet_entities[:user_mentions].map { |h| h['indices'] } if options[:strip_user_mentions]
    indices_for_stripping << tweet_entities[:urls].map { |h| h['indices'] }          if options[:strip_urls]
    indices_for_stripping << tweet_entities[:hashtags].map { |h| h['indices'] }      if options[:strip_hastags]

    # order indices array by indices descending and then slicing entities to remove
    indices_for_stripping.flatten(1).sort { |a, b| b[0] <=> a[0] }.each do |indices|
      tweet_text.slice!(indices[0]..indices[1])
    end

    tweet_text = tweet_text.gsub(/(\s?\/\s*cc\s\@\w+)/, '') if options[:strip_cc]
    tweet_text = tweet_text.gsub(/\s*[:-]\s*$/, '') if options[:strip_cc]

    tweet_text.strip
  end

  def clean_tweet_from_user(tweet)
    tweet.user.name.titleize
  end

end
