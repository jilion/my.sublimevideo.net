require 'configurator'

class SessionSecretToken
  include Configurator

  config_file 'session_secret_token.yml'
  config_accessor :session_secret_token
end
