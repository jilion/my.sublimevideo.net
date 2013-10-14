Sidekiq.configure_client do |config|
  config.redis = { size: 2 } # for web dyno
end
