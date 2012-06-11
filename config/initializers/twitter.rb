require_dependency 'twitter_api'

Twitter.configure do |config|
  config.consumer_key       = TwitterApi.consumer_key
  config.consumer_secret    = TwitterApi.consumer_secret
  config.oauth_token        = TwitterApi.oauth_token
  config.oauth_token_secret = TwitterApi.oauth_token_secret
end
