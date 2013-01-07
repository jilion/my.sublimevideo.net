Airbrake.configure do |config|
  config.api_key = 'd83280c89d59e2babd2e3ee1c546e8d4'
  config.ignore  << ActionController::UnknownHttpMethod
  config.ignore  << Errno::EPIPE
  config.ignore  << Errno::ETIMEDOUT
  config.ignore  << Errno::ECONNRESET
  config.ignore  << Timeout::Error
  config.ignore  << Excon::Errors::SocketError
  config.ignore  << Excon::Errors::InternalServerError
end
