require 'configurator'

class GetSatisfactionWrapper
  include Configurator

  config_file 'get_satisfaction.yml', rails_env: false
end
