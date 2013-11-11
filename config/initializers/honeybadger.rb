Honeybadger.configure do |config|
  config.api_key = ENV['HONEYBADGER_API_KEY']
  config.ignore << 'Redis::TimeoutError'
  config.ignore << 'CreateSend::ServerError'
end
