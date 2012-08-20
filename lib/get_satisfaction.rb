require_dependency 'configurator'

class GetSatisfaction
  include Configurator

  config_file 'get_satisfaction.yml', rails_env: false
end
