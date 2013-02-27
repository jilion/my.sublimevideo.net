require 'configurator'

class GetSatisfactionWrapper
  include Configurator

  config_file 'get_satisfaction.yml', rails_env: false
  config_accessor :consumer_key, :consumer_secret
end
