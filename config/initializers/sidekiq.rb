Sidekiq.options = {
  queues: ['low', 'default', 'high', 'mailer'],
  concurrency: 25,
  require: '.',
  timeout: 8,
  poll_interval: 5
}

# http://mongoid.org/en/mongoid/docs/tips.html#sidekiq
Sidekiq.configure_server do |config|
  config.server_middleware do |chain|
    chain.add Kiqstand::Middleware
  end
end
