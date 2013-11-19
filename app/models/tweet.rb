# coding: utf-8
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

  belongs_to :retweeted_tweet, class_name: 'Tweet', inverse_of: :retweets
  has_many   :retweets, class_name: 'Tweet', inverse_of: :retweeted_tweet

  KEYWORDS = ['jilion', 'sublimevideo', 'aelios', 'aeliosapp', 'videojs', 'jw player']

  scope :keywords,          ->(keywords) { where(keywords: keywords) }
  scope :favorites,         -> { where(favorited: true) }
  scope :by_date,           ->(way = 'desc') { order_by([:tweeted_at, way]) }
  scope :by_retweets_count, ->(way = 'desc') { order_by([:retweets_count, way]) }

  validates :tweet_id, :from_user_id, :content, :tweeted_at, presence: true
  validates :tweet_id, uniqueness: true

  def self.create_from_twitter_tweet!(tweet)
    create!(
      tweet_id:          tweet.id,
      keywords:          KEYWORDS.select { |k| tweet.text.downcase.include?(k.downcase) },
      from_user_id:      tweet.from_user_id || tweet.user.id,
      from_user:         tweet.from_user,
      to_user_id:        tweet.to_user_id,
      to_user:           tweet.to_user,
      iso_language_code: tweet.lang,
      profile_image_url: tweet.user.profile_image_url_https,
      source:            tweet.source,
      content:           tweet.text,
      tweeted_at:        tweet.created_at
    )
  end

  def favorite!
    result = if favorited?
      TwitterWrapper.unfavorite(tweet_id)
    else
      TwitterWrapper.favorite(tweet_id)
    end
    update_attribute(:favorited, !favorited) unless result.nil?
  end

end
