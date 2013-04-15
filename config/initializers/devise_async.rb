Devise::Async.setup do |config|
  config.backend = :sidekiq
  config.mailer  = Devise.mailer.to_s
end
