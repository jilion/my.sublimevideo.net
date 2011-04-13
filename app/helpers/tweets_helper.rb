module TweetsHelper

  def clean_tweet_text(tweet, *args)
    tweet_text     = tweet.text
    tweet_entities = tweet.entities
    options        = args.extract_options!
    indices_for_stripping = []

    indices_for_stripping << tweet_entities.user_mentions.map(&:indices) if options[:strip_user_mentions]
    indices_for_stripping << tweet_entities.urls.map(&:indices)          if options[:strip_urls]
    indices_for_stripping << tweet_entities.hashtags.map(&:indices)      if options[:strip_hastags]

    # order indices array by indices descending and then slicing entities to remove
    indices_for_stripping.flatten(1).sort { |a, b| b[0] <=> a[0] }.each do |indices|
      tweet_text.slice!(indices[0]..indices[1])
    end

    tweet_text = tweet_text.gsub(/(\s?\/\s*cc\s\@\w+)/, '') if options[:strip_cc]

    tweet_text.strip
  end

  def clean_tweet_from_user(tweet)
    tweet.user.name.titleize
  end

end
