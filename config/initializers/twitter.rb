Twitter.configure do |config|
  config.consumer_key       = TwitterWrapper.consumer_key
  config.consumer_secret    = TwitterWrapper.consumer_secret
  config.oauth_token        = TwitterWrapper.oauth_token
  config.oauth_token_secret = TwitterWrapper.oauth_token_secret
end
