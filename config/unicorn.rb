worker_processes Integer(ENV['WEB_CONCURRENCY'] || 2)
timeout Integer(30)
preload_app true

before_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn master intercepting TERM and sending myself QUIT instead'
    Process.kill 'QUIT', Process.pid
  end

  Sidekiq.configure_client do |config|
    config.redis = { size: 2 } # for web dyno
  end

  defined?(ActiveRecord::Base) and ActiveRecord::Base.connection.disconnect!
end

after_fork do |server, worker|
  Signal.trap 'TERM' do
    puts 'Unicorn worker intercepting TERM and doing nothing. Wait for master to sent QUIT'
  end

  if defined?(ActiveRecord::Base)
    config = Rails.application.config.database_configuration[Rails.env]
    config['reaping_frequency'] = ENV['DB_REAP_FREQ'] || 10 # seconds
    config['pool']              = ENV['DB_UNICORN_POOL'] || 5
    ActiveRecord::Base.establish_connection(config)
  end

  Sidekiq.configure_client do |config|
    config.redis = { size: 2 } # for web dyno
  end
end
