Airbrake.configure do |config|
  config.api_key = 'd83280c89d59e2babd2e3ee1c546e8d4'
  config.ignore  << ActionController::UnknownHttpMethod
  config.ignore  << Errno::EPIPE
  config.ignore  << Excon::Errors::SocketError
end
