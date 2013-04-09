require 'configurator'

class SessionSecret
  include Configurator

  config_file 'session_secret.yml'
  config_accessor :token
end
