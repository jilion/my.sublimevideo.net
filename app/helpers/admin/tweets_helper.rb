# coding: utf-8
module Admin::TweetsHelper

  def admin_tweets_page_title(tweets, retweets = 0)
    pluralized_tweets = pluralize(tweets.count, 'tweet')

    state = if params[:keywords]
      " mentioning “#{params[:keywords]}”"
    else
      ''
    end
    "#{pluralized_tweets.titleize}#{state}"
  end

end
