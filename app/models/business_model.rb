require 'configurator'

class BusinessModel
  include Configurator

  config_file 'business_model.yml', rails_env: false
end
