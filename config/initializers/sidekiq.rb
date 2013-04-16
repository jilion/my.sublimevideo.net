Sidekiq.configure_server do |config|
  if database_url = ENV['DATABASE_URL']
    ENV['DATABASE_URL'] = "#{database_url}?pool=52"
    ActiveRecord::Base.establish_connection
  end

  # http://mongoid.org/en/mongoid/docs/tips.html#sidekiq
  config.server_middleware do |chain|
    chain.add Kiqstand::Middleware
  end
end

Sidekiq.configure_client do |config|
  config.redis = { size: 2 } # for web dyno
end
