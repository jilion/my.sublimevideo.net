Mongoid.configure do |config|
  config.use_utc = true
  config.max_retries_on_connection_failure = 3
end
