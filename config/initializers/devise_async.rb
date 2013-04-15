Devise::Async.setup do |config|
  config.backend = :sidekiq
  config.mailer  = Devise.mailer
end
