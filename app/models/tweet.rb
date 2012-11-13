# coding: utf-8
require_dependency 'twitter_api'

class Tweet
  include Mongoid::Document

  field :tweet_id,          type: Integer # returned as id from Twitter
  field :keywords,          type: Array, default: [] # ['sublimevideo', 'jilion'] for example
  field :from_user_id,      type: Integer
  field :from_user,         type: String
  field :to_user_id,        type: Integer
  field :to_user,           type: String
  field :iso_language_code, type: String
  field :profile_image_url, type: String
  field :source,            type: String
  field :content,           type: String   # returned as text from Twitter
  field :tweeted_at,        type: DateTime # returned as created_at from Twitter
  field :retweets_count,    type: Integer, default: 0 # can be retrieved with http://api.twitter.com/version/statuses/show/:id.format
  field :favorited,         type: Boolean, default: false # can be retrieved with http://api.twitter.com/version/statuses/show/:id.format

  index tweet_id: 1
  index favorited: 1
  index tweeted_at: 1
  index keywords: 1

  belongs_to :retweeted_tweet, class_name: "Tweet", inverse_of: :retweets
  has_many   :retweets, class_name: "Tweet", inverse_of: :retweeted_tweet

  KEYWORDS = ["jilion", "sublimevideo", "aelios", "aeliosapp", "videojs", "jw player"]

  attr_accessible :tweet_id, :keywords, :from_user_id, :from_user, :to_user_id, :to_user, :iso_language_code, :profile_image_url, :source, :content, :tweeted_at, :retweets_count

  scope :keywords,          lambda { |keywords| where(keywords: keywords) }
  scope :favorites,         where(favorited: true)
  scope :by_date,           lambda { |way='desc'| order_by([:tweeted_at, way]) }
  scope :by_retweets_count, lambda { |way='desc'| order_by([:retweets_count, way]) }

  # ===============
  # = Validations =
  # ===============

  validates :tweet_id, :from_user_id, :content, :tweeted_at, presence: true
  validates :tweet_id, uniqueness: true

  # =================
  # = Class Methods =
  # =================

  class << self

    def save_new_tweets_and_sync_favorite_tweets
      KEYWORDS.each do |keyword|
        max_id = nil
        while search = remote_search(keyword, max_id: max_id) and search.results.present?
          search.results.each do |tweet|
            if t = self.where(tweet_id: tweet.id).first
              t.add_to_set(:keywords, keyword) unless t.keywords.include?(keyword)
            else
              self.create_from_twitter_tweet!(tweet)
            end
          end
          max_id = search.max_id
        end
      end
      self.sync_favorite_tweets
    end

    def remote_search(keyword, options = {})
      TwitterApi.search("\"#{keyword}\"", result_type: 'recent', count: 100, since_id: options[:max_id])
    end

    def remote_favorites(options = {})
      TwitterApi.favorites('sublimevideo', page: options[:page], include_entities: options[:include_entities])
    end

    def create_from_twitter_tweet!(tweet)
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
        tweeted_at:        tweet.created_at
      )
    end

    # This method synchronize the locals favorites tweets with the favorites tweets of @sublimevideo on Twitter
    # It will never favorite/un-favorite tweets on Twitter
    # It simply favorite/un-favorite tweets locally regarding favorites tweets on Twitter
    def sync_favorite_tweets
      twitter_favorites_ids = (remote_favorites(include_entities: false) || []).map(&:id)
      local_favorites_ids   = favorites.only(:tweet_id).map(&:tweet_id)

      to_add    = twitter_favorites_ids - local_favorites_ids
      to_remove = local_favorites_ids - twitter_favorites_ids

      to_add.each do |fav_tweet_id_to_add|
        if tweet = self.where(tweet_id: fav_tweet_id_to_add).first
          tweet.update_attribute(:favorited, true)
        end
      end

      # if to_remove.present?
      #   Notify.send("These tweets are marked as favorite locally but not on Twitter: #{to_remove.join(', ')}")
      #   to_remove.each do |fav_tweet_id_to_remove|
      #     if tweet = self.where(tweet_id: fav_tweet_id_to_remove).first
      #       tweet.update_attribute(:favorited, false)
      #     end
      #   end
      # end
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
    def pretty_remote_favorites(*args)
      options = args.extract_options!
      options.assert_valid_keys([:user_doublon, :count, :random, :since_date, :include_entities])
      options = options.reverse_merge({
        user_doublon: true,
        count: 0,
        random: false,
        since_date: nil,
        include_entities: false
      })

      page = 1
      tweets = []

      while favorites = remote_favorites(page: page, include_entities: options[:include_entities])
        break if favorites.blank?
        favorites.each do |tweet|
          break if options[:since_date] && tweet.created_at < options[:since_date]
          tweets << tweet
        end
        page += 1
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

      selected_tweets.sort { |a, b| b.created_at <=> a.created_at }[0...count]
    end

  end

  # ====================
  # = Instance Methods =
  # ====================

  def favorite!
    result = if favorited?
      TwitterApi.favorite_destroy(self.tweet_id)
    else
      TwitterApi.favorite_create(self.tweet_id)
    end
    self.update_attribute(:favorited, !favorited) unless result.nil?
  end

end
