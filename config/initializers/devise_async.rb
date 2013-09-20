Devise::Async.setup do |config|
  config.enabled = !Rails.env.development?
  config.backend = :sidekiq
  config.queue   = 'my-mailer'
end
