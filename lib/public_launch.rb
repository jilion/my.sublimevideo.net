require_dependency 'configurator'

class PublicLaunch
  include Configurator

  config_file 'public_launch.yml', rails_env: false
  config_accessor :beta_transition_started_on
end
