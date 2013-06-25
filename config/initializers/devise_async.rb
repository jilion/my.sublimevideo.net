Devise::Async.setup do |config|
  config.enabled = !Rails.env.development?
  config.backend = :sidekiq
end
