require 'highrise'
require_dependency 'configurator'

module HighriseWrapper
  include Configurator

  config_file 'highrise.yml'
  config_accessor :url, :api_token
end
