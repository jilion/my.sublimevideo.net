Sidekiq.configure_client do |config|
  config.poll_interval = 5
end

# http://mongoid.org/en/mongoid/docs/tips.html#sidekiq
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Kiqstand::Middleware
  end
end
