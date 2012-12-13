web:    bundle exec rails server thin -p $PORT
worker: bundle exec sidekiq -C config/sidekiq_cli.yml
log_worker: REDIS_SIZE=1 bundle exec sidekiq -C config/sidekiq_log_cli.yml
