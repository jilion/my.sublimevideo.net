web:    bundle exec rails server thin -p $PORT
worker: bundle exec sidekiq -C config/sidekiq_cli.yml
log_worker: bundle exec sidekiq -C config/sidekiq_log_cli.yml
