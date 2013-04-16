require 'configurator'

class BusinessModel
  include Configurator

  config_file 'business_model.yml', rails_env: false
  config_accessor :days_for_trial, :days_before_trial_end
end
