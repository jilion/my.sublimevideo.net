require_dependency 'configurator'

class Api
  include Configurator

  config_file 'api.yml', rails_env: false
end
