# coding: utf-8
class Tweet
  include Mongoid::Document

  field :tweet_id,          :type => Integer # returned as id from Twitter
  field :keywords,          :type => Array, :default => [] # ['sublimevideo', 'jilion'] for example
  field :from_user_id,      :type => Integer
  field :from_user,         :type => String
  field :to_user_id,        :type => Integer
  field :to_user,           :type => String
  field :iso_language_code, :type => String
  field :profile_image_url, :type => String
  field :source,            :type => String
  field :content,           :type => String   # returned as text from Twitter
  field :tweeted_at,        :type => DateTime # returned as created_at from Twitter
  field :retweets_count,    :type => Integer, :default => 0 # can be retrieved with http://api.twitter.com/version/statuses/show/:id.format
  field :favorited,         :type => Boolean, :default => false # can be retrieved with http://api.twitter.com/version/statuses/show/:id.format

  index [:tweeted_at, Mongo::ASCENDING]
  index :keywords

  belongs_to :retweeted_tweet, :class_name => "Tweet", :inverse_of => :retweets
  has_many   :retweets, :class_name => "Tweet", :inverse_of => :retweeted_tweet

  KEYWORDS = ["jilion", "sublimevideo", "aelios", "aeliosapp", "videojs", "jw player"]

  attr_accessor :bigger_profile_image

  attr_accessible :tweet_id, :keywords, :from_user_id, :from_user, :to_user_id, :to_user, :iso_language_code, :profile_image_url, :source, :content, :tweeted_at, :retweets_count

  scope :keywords,  lambda { |keywords| where(keywords: keywords) }
  scope :favorites, lambda { |favorite=true| where(favorited: true) }
  scope :by_date,   lambda { |way='desc'| order_by([:tweeted_at, way]) }
  scope :by_retweets_count, lambda { |way='desc'| order_by([:retweets_count, way]) }

  # ===============
  # = Validations =
  # ===============

  validates :tweet_id, :from_user_id, :content, :tweeted_at, :presence => true
  validates :tweet_id, :uniqueness => true

  # =================
  # = Class Methods =
  # =================
  def self.delay_save_new_tweets_and_sync_favorite_tweets
    unless Delayed::Job.already_delayed?('%Tweet%save_new_tweets_and_sync_favorite_tweets%')
      delay(priority: 200, run_at: 20.minutes.from_now).save_new_tweets_and_sync_favorite_tweets
    end
  end

  def self.save_new_tweets_and_sync_favorite_tweets
    delay_save_new_tweets_and_sync_favorite_tweets
    return unless enough_remaining_twitter_calls?

    search = TwitterApi.search.new

    KEYWORDS.each do |keyword|
      search.clear
      search.q("\"#{keyword}\"").per_page(100)
      i = 1

      loop do
        # Rails.logger.info("Searching for #{keyword}, with 100 results per page (page #{i})")
        search.fetch.each do |tweet|
          begin
            if t = self.where(tweet_id: tweet.id).first
              t.add_to_set(:keywords, keyword) unless t.keywords.include?(keyword)
            else
              self.create_from_twitter_tweet!(tweet)
            end
          rescue => ex
            Notify.send("Tweet (tweet_id: #{tweet.id} could not be saved?!", exception: ex)
          end
        end
        break unless search.next_page?
        i += 1
        search.fetch_next_page
      end
    end
    self.sync_favorite_tweets
  end

  def self.create_from_twitter_tweet!(tweet)
    self.create!(
      tweet_id:          tweet.id,
      keywords:          KEYWORDS.select { |k| tweet.text.downcase.include?(k.downcase) },
      from_user_id:      tweet.from_user_id || tweet.user.id,
      from_user:         tweet.from_user,
      to_user_id:        tweet.to_user_id,
      to_user:           tweet.to_user,
      iso_language_code: tweet.iso_language_code,
      profile_image_url: tweet.profile_image_url,
      source:            tweet.source,
      content:           tweet.text,
      tweeted_at:        Time.zone.parse(tweet.created_at)
    )
  end

  # This method synchronize the locals favorites tweets with the favorites tweets of @sublimevideo on Twitter
  # It will never favorite/un-favorite tweets on Twitter
  # It simply favorite/un-favorite tweets locally regarding favorites tweets on Twitter
  def self.sync_favorite_tweets
    return unless enough_remaining_twitter_calls?(10)

    twitter_favorites_ids = self.favorites_tweets.map(&:id)
    local_favorites_ids   = self.favorites.only(:tweet_id).map(&:tweet_id)

    to_add    = twitter_favorites_ids - local_favorites_ids
    to_remove = local_favorites_ids - twitter_favorites_ids

    to_add.each do |fav_tweet_id_to_add|
      if tweet = self.where(tweet_id: fav_tweet_id_to_add).first
        tweet.update_attribute(:favorited, true)
      end
    end

    if to_remove.present?
      Notify.send("These tweets are marked as favorite locally but not on Twitter: #{to_remove.join(', ')}")
      to_remove.each do |fav_tweet_id_to_remove|
        if tweet = self.where(tweet_id: fav_tweet_id_to_remove).first
          tweet.update_attribute(:favorited, false)
        end
      end
    end
  end

  # Return a certain number of random favorites tweets of a user, ordered by date desc FROM Twitter.
  #
  # Options:
  # - user: a Twitter username (default: 'sublimevideo')
  # - user_doublon: if you allow more than 1 tweet by the same user (default: true)
  # - count: number of favorites to return (default: 0)
  # - random: if you want to return tweets randomly (default: false)
  # - since_date: return favorites only after since_date (default: nil)
  # - include_entities: wether to include entities in results or not (default: false)
  def self.favorites_tweets(*args)
    options = args.extract_options!
    options.assert_valid_keys([:user_doublon, :count, :random, :since_date, :include_entities])
    options = options.reverse_merge({
      user: 'sublimevideo',
      user_doublon: true,
      count: 0,
      random: false,
      since_date: nil,
      include_entities: false
    })

    page = 1
    tweets, favorites = [], TwitterApi.favorites(options[:user], page: page, include_entities: options[:include_entities])

    while favorites.present?
      favorites.each do |tweet|
        tweet = self.tweet_with_parsed_date(tweet)
        break if options[:since_date] && tweet.created_at < options[:since_date]
        tweets << tweet
      end
      page += 1
      favorites = TwitterApi.favorites(options[:user], page: page, include_entities: options[:include_entities])
    end

    count = if options[:count] == 0
      tweets.size
    else
      [(options[:user_doublon] ? tweets.size : tweets.map { |tweet| tweet.user.id }.uniq.size), options[:count]].min
    end

    selected_tweets = options[:random] ? [] : tweets
    if options[:random]
      while selected_tweets.size < count
        t = tweets.sample
        selected_tweets << t if options[:user_doublon] || selected_tweets.map { |tweet| tweet.user.id }.exclude?(t.user.id)
      end
    end

    selected_tweets.each do |tweet|
      begin
        tweet.bigger_profile_image = TwitterApi.profile_image(tweet.user.id, size: 'bigger')
      rescue => ex
        selected_tweets.delete(tweet)
      end
    end
    selected_tweets.sort { |a, b| b.created_at <=> a.created_at }[0...count]
  end

  def self.tweet_with_parsed_date(tweet)
    tweet.created_at = Time.zone.parse(tweet.created_at)
    tweet
  end

  def self.enough_remaining_twitter_calls?(count=0)
    TwitterApi.rate_limit_status.remaining_hits >= (count.zero? ? KEYWORDS.size * 3 : count)
  end

  def self.time_until_next_twitter_calls_limit_reset
    Time.zone.at(TwitterApi.rate_limit_status.reset_time_in_seconds) - Time.now.utc
  end

  # not ready yet
  # def self.process_retweets
  #   twitter_rate_limit_status = Twitter.rate_limit_status
  #   unless Delayed::Job.already_delayed?('%Tweet%process_retweets%')
  #     delay({
  #       run_at: Time.zone.at(twitter_rate_limit_status.reset_time_in_seconds) + 2.minutes
  #     }).process_retweets
  #   end
  #   max_to_process_during_this_hour = (twitter_rate_limit_status.remaining_hits * 0.75).to_i
  #   # Rails.logger.info(max_to_process_during_this_hour)
  #   # Rails.logger.info(Tweet.where(:tweeted_at => { "$gte" => 1.week.ago }).count)
  #
  #   Tweet.where(:tweeted_at => { "$gte" => 1.week.ago }).limit(max_to_process_during_this_hour).order_by(:id).all.each do |tweet|
  #     twitter_retweets = Twitter.retweets(tweet.tweet_id, count: 100, trim_user: false)
  #     twitter_retweets.each do |twitter_retweet|
  #       # we should make an individual call for each new tweet in order to have the "from_user", "profile_image_url" etc.
  #       tweet.retweets << (Tweet.where(tweet_id: twitter_retweet.id).first || self.create_from_twitter_tweet!(twitter_retweet))
  #       Rails.logger.info("Tweet ##{tweet.retweets.last.id} was retweeted from ##{tweet.id}!")
  #     end
  #     tweet.retweets_count = tweet.retweets.size
  #     tweet.save
  #   end
  #   Rails.logger.info("Retweets processing finished!")
  # end

  # ====================
  # = Instance Methods =
  # ====================

  def favorite!
    if favorited?
      TwitterApi.favorite_destroy(self.tweet_id)
    else
      TwitterApi.favorite_create(self.tweet_id)
    end
    self.update_attribute(:favorited, !favorited)
  end

end
